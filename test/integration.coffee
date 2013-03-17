should = require 'should'
{Collector, Stream} = require '../.'
mongoWatchPolicy = require '../sample/mongoWatchPolicy'
{Server, Db, ObjectID} = require 'mongodb'
{isEqual} = require 'lodash'
{inspect} = require 'util'
{getType} = require '../lib/util'
_ = require 'lodash'
logger = (args...) -> console.log args.map((a) -> if (typeof a) is 'string' then a else inspect a, null, null)...

describe 'Integration', ->

  describe 'with MongoWatch', ->

    before (done) ->

      # Given a ref for modifying 'users'
      client = new Db 'test', new Server('localhost', 27017), {w: 1}
      client.open (err) =>
        return done err if err

        client.collection 'users', (err, @users) =>

          # And a Stream listening to MongoWatch
          @stream = new Stream mongoWatchPolicy @users
          done err

    afterEach ->
      @stream.disconnect() if @stream
      @users.remove {}, ->

    it 'should emit events', (done) ->

      @collector = new Collector
        #onDebug: console.log
        identity: {sessionId: 5}
        register: @stream.register.bind @stream

        # I should recieve a delta event
        onData: (data, event) =>
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
          done()

      @collector.ready =>
        @collector.data.should.eql {users: []}

      # And something event worthy happens
      @users.insert {email: 'graham@daventry.com'}, (err, status) ->
        should.not.exist err

    it 'should work with sub documents', (done) ->

      # Given I have a user record with a sub document
      initialRecord =
        email: 'graham@daventry.com'
        friends: [
            name: 'Bob'
          ,
            name: 'Sally'
        ]

      @users.insert initialRecord, (err) =>
        should.not.exist err

        # mongoose is modifying the arg I gave it to add an _id
        initialRecord.id = initialRecord._id.toString()
        delete initialRecord._id

        @collector = new Collector
          onDebug: logger
          identity: {sessionId: 5}
          register: @stream.register.bind @stream

          # I should recieve a delta event
          onData: (data, event) =>
            if event?.oplist?[0]?.operation is 'push'
              event.oplist[0].should.eql {
                operation: 'push'
                id: initialRecord.id
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
                  id: initialRecord.id
                }]
              done()

        @collector.ready =>
          should.exist @collector.data?.users?[0]
          @collector.data.users[0].should.eql initialRecord

          @users.update {_id: new ObjectID initialRecord.id}, {'$push': friends: {name: 'Jim'}}, (err) ->
            should.not.exist err
