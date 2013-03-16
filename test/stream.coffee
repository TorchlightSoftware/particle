should = require 'should'
{Stream} = require '../'
mongoWatchPolicy = require '../sample/mongoWatchPolicy'
{Server, Db} = require 'mongodb'
{isEqual} = require 'lodash'

describe 'Stream', ->

  describe 'with MongoWatch', ->

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

    it 'insert should emit an event', (done) ->

      # Given a Stream listening to MongoWatch
      @stream = new Stream mongoWatchPolicy @users

      # Then the receiver should return the expected data
      receiver = (name, event) =>
        should.exist event.timestamp

        switch name

          # I should receive a manifest
          when 'manifest'
            event.should.include {
              users:
                email: true
                todo:
                  list: true
            }

          # And I should receive a payload
          when 'payload'
            event.should.include {
              data: []
              root: 'users'
            }

            # When something event worthy happens
            # (only trigger this once initial data has been received)
            @users.insert {email: 'graham@daventry.com'}, (err, status) ->
              should.not.exist err

          when 'delta'

            # Then I should receive a delta
            {root, oplist} = event
            [{data, operation}] = oplist

            root.should.eql 'users'
            operation.should.eql 'set'
            data.email.should.eql 'graham@daventry.com'
            done()

      # When a receiver is registered
      @stream.register {sessionId: 5}, receiver, (err) =>
        should.not.exist err
