should = require 'should'
{Collector, Stream} = require '../.'
mongoWatchPolicy = require '../sample/mongoWatchPolicy'
{Server, Db, ObjectID} = require 'mongodb'
{getType} = require '../lib/util'
{inspect} = require 'util'
logger = (args...) -> console.log args.map((a) -> if (typeof a) is 'string' then a else inspect a, null, null)...
accumulator = require 'accumulator'

tests = [
    description: 'should emit events'
    identity: {sessionId: 5}

    # Given no users

    ready: (next) ->

      # I should see no users when the client initializes
      @collector.data.should.eql {users: []}

      # When I insert a user
      @users.insert {email: 'graham@daventry.com'}, next

    listen:
      'Then I should see a delta':
        on: 'users'
        do: (data, event, next) ->
          should.exist event
          should.exist event.root, 'expected root'
          event.root.should.eql 'users'
          (getType event.oplist).should.eql 'Array'
          event.oplist.should.have.length 1

          should.exist data
          should.exist data?.users?[0]?.id, 'expected user id'
          should.exist data?.users?[0]?.email, 'expected user email'

          expected = [
            operation: 'set'
            id: event.oplist[0].id
            path: '.'
            data:
              email: 'graham@daventry.com'
              id: event.oplist[0].id
          ]

          event.oplist.should.eql expected
          next()

  ,
    description: 'should work with sub documents'

    # Given I have a user record with a sub document
    pre: (next) ->
      @initialRecord =
        email: 'graham@daventry.com'
        friends: [
            name: 'Bob'
          ,
            name: 'Sally'
        ]

      @users.insert @initialRecord, (args...) =>

        # mongoose is modifying the arg I gave it to add an _id
        @initialRecord.id = @initialRecord._id.toString()
        delete @initialRecord._id

        next args...


    identity: {sessionId: 5}

    listen:
      'I should recieve a delta event':
        on: 'users'
        do: (data, event, next) ->
          if event?.oplist?[0]?.operation is 'push'
            event.oplist[0].should.eql {
              operation: 'push'
              id: @initialRecord.id
              path: 'friends'
              data: {name: 'Jim'}
            }
            data.should.eql
              users: [{
                email: 'graham@daventry.com'
                friends: [
                    name: 'Bob'
                  ,
                    name: 'Sally'
                  ,
                    name: 'Jim'
                ]
                id: @initialRecord.id
              }]
            next()

    ready: (next) ->
      should.exist @collector.data?.users?[0]

      @collector.data.users[0].should.eql @initialRecord

      @users.update {_id: new ObjectID @initialRecord.id}, {'$push': friends: {name: 'Jim'}}, next
]

# create a test harness which turns the above test data into live tests
describe 'Stream', ->
  before (done) ->

    # create a ref for modifying 'users'
    client = new Db 'test', new Server('localhost', 27017), {w: 1}
    client.open (err) =>
      return done err if err

      client.collection 'users', (err, @users) =>
        done err

  afterEach ->
    @stream.disconnect() if @stream
    @users.remove {}, ->

  for test in tests
    do (test) ->
      {identity, description, pre, listen, onDebug, ready} = test

      defaultFn = (next) -> next()
      pre or= defaultFn
      ready or= defaultFn

      it description, (done) ->
        getCb = accumulator done
        readyCb = getCb()

        handlers = for name, listener of listen
          data =
            ds: name
            on: listener.on
            do: listener.do
            cb: getCb()

        pre.call @, (err) =>
          should.not.exist err, 'failed pre-condition'

          @stream = new Stream mongoWatchPolicy @users

          @collector = new Collector
            identity: identity
            onDebug: onDebug
            register: @stream.register.bind @stream

            onData: (data, event) =>
              for handler in handlers when event.root is handler.on
                handler.do.call @, data, event, (err) ->
                  should.not.exist err, handler.ds
                  handler.cb err

          @collector.ready ready.bind @, readyCb
