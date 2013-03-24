should = require 'should'
{Stream} = require '../'
mongoWatchPolicy = require '../sample/mongoWatchPolicy'
{Server, Db, ObjectID} = require 'mongodb'
_ = require 'lodash'
logger = require './helpers/logger'

tests = [
    description: 'insert should emit an event'
    identity: {sessionId: 5}

    # Given I set a manifest
    manifest:
      email: true
      todo:
        list: true

    listen:

      'Then I should receive a manifest':
        on: 'manifest'
        do: (event, next) ->
          event.should.include {
            users:
              email: true
              todo:
                list: true
          }
          next()

      'And a payload':
        on: 'payload'
        do: (event, next) ->
          event.should.include {
            data: []
            root: 'users'
          }

          # When I insert a document
          @users.insert {email: 'graham@daventry.com'}, next

      'And a delta':
        on: 'delta'
        do: (event, next) ->
          {root, oplist} = event
          [{data, operation}] = oplist

          root.should.eql 'users'
          operation.should.eql 'set'
          data.email.should.eql 'graham@daventry.com'
          next()
  ,
    description: 'push should be supported'
    identity: {sessionId: 5}

    # Given I insert a document
    pre: (done) ->
      @users.insert {email: 'graham@daventry.com'}, done

    listen:

      'And I receive a payload':
        on: 'payload'
        do: (event, next) ->
          should.exist event?.data?[0]
          event.data[0].should.include {email: 'graham@daventry.com'}
          @id = event.data[0].id

          # When I update with a push
          @users.update {_id: new ObjectID @id}, {'$push': friends: {name: 'Jim'}}, (err) ->
            next err

      'Then I should receive a delta':
        on: 'delta'
        do: (event, next) ->
          should.exist event?.oplist?[0]
          if _.isEqual event.oplist[0], {
            id: @id
            operation: 'push'
            path: 'friends'
            data: {name: 'Jim'}
          }
            next()
  ,
    description: 'should not allow payload for items not in manifest'
    manifest:
      email: true
      todo:
        list: true
    identity: {sessionId: 5}

    # Given I insert a document with fields outside the manifest
    pre: (done) ->
      @users.insert {email: 'graham@daventry.com', shouldNotAllow: 'gotcha'}, done

    listen:

      'I should receive a manifest':
        on: 'manifest'
        do: (event, next) ->
          event.should.include {
            users:
              email: true
              todo:
                list: true
          }
          next()

      'The payload should not include items outside the manifest':
        on: 'payload'
        do: (event, next) ->
          should.not.exist event.data[0].shouldNotAllow

          # When I update a document
          @users.update {email: 'graham@daventry.com'}, {email: 'foo@bar.com', something: 'yes'}, next

      'And the delta should not include items outside the manifest':
        on: 'delta'
        do: (event, next) ->
          {root, oplist} = event
          [{data, operation}] = oplist

          root.should.eql 'users'
          operation.should.eql 'set'
          should.not.exist data.something
          next()
  ,
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
      {identity, manifest, description, listen, pre} = test
      pre or= (next) -> next()

      it description, (done) ->
        return done() if Object.keys(listen).length is 0
        pre.bind(@) (err) =>
          should.not.exist err, 'failed pre-condition'

          @stream = new Stream mongoWatchPolicy @users, manifest

          receiver = (name, event) =>
            for message, listener of listen when listener.on is name
              do (message, listener) =>
                listener.do.bind(@) event, (err) ->
                  should.not.exist err, message
                  delete listen[message]
                  if Object.keys(listen).length is 0
                    done()

          @stream.register {sessionId: 5}, receiver, (err) =>
