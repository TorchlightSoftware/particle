should = require 'should'
{Collector, Stream} = require '../.'
mongoWatchPolicy = require '../sample/mongoWatchPolicy'
{Server, Db} = require 'mongodb'
{isEqual} = require 'lodash'
{inspect} = require 'util'
{getType} = require '../lib/util'
_ = require 'lodash'

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
