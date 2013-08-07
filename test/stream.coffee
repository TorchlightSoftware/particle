should = require 'should'
_ = require 'lodash'
logger = require 'torch'
{sample} = require 'ale'
{EventEmitter} = require 'events'
#{Server, Db, ObjectID} = require 'mongodb'

limit = require './helpers/limit'
{Stream} = require '../'
samplePolicy = require('../sample/data/samplePolicy')()

describe 'Stream', ->
  beforeEach ->
    @collector = new EventEmitter
    @collector.on 'receive', (origin, event) =>
      @collector[origin] ?= []
      @collector[origin].push event
    @receiver = @collector.emit.bind(@collector, 'receive')

    @identity =
      userId: 4
      accountId: 1

  it 'should retrieve payload for visibleUsers', (done) ->
    policy = limit samplePolicy, ['visibleUsers']
    #policy.onDebug = logger.grey
    stream = new Stream policy
    stream.register @identity, @receiver, (err) =>
      #logger.white @collector

      @collector.manifest.length.should.eql 1
      _.keys(@collector.manifest[0]).should.eql ['timestamp', 'visibleUsers']

      @collector.payload.length.should.eql 2
      [bob, jane] = @collector.payload
      bob.should.include {
        origin: 'payload'
        namespace: 'test.users'
        _id: 4
        operation: 'set'
        path: '.'
        data: { _id: 4, accountId: 1, name: 'Bob', email: 'bob@foo.com' }
      }
      jane.should.include {
        origin: 'end payload'
        namespace: 'test.users'
        _id: 5
        operation: 'set'
        path: '.'
        data: { _id: 5, accountId: 1, name: 'Jane', email: 'jane@foo.com' }
      }
      done()

  it 'should update on new users', (done) ->
    policy = limit samplePolicy, ['visibleUsers']
    #policy.onDebug = logger.grey
    stream = new Stream policy
    stream.ready =>
      stream.register @identity, @receiver, (err) =>

        @collector.payload.length.should.eql 2

        collName = 'users'

        policy.adapter.once "#{collName}:receivedUpdate", ({newIdSet}) ->
          newIdSet.should.eql [4, 5, 3]
          done()

        policy.adapter.send collName, {
          namespace: "test.#{collName}"
          origin: 'delta'
          timestamp: new Date
          _id: 3
          operation: 'set'
          path: '.'
          data:
            _id: 3
            accountId: 1
            name: 'Kim'
            email: 'kim@foo.com'
        }

  it 'should retrieve payload for myStuff', (done) ->
    policy = limit samplePolicy, ['myStuff']
    #policy.onDebug = logger.grey
    stream = new Stream policy
    stream.register @identity, @receiver, (err) =>

      @collector.manifest.length.should.eql 1
      _.keys(@collector.manifest[0]).should.eql ['timestamp', 'myStuff']

      @collector.payload.length.should.eql 2
      stuff = _.map @collector.payload, 'data'
      stuff.should.eql [
          _id: 1
          stuff: [ 'foo', 'bar' ]
        ,
          _id: 2
          stuff: [ 'baz' ]
      ]
      done()

  it 'should update on new stuff', (done) ->
    policy = limit samplePolicy, ['myStuff']
    #policy.onDebug = logger.grey
    stream = new Stream policy
    stream.register @identity, @receiver, (err) =>

      @collector.payload.length.should.eql 2


      # we're getting duplicate notifications due to reverse relations updating
      sample policy.adapter, "stuffs:receivedUpdate", 2, (err, events) ->
        [[{newIdSet}]] = events
        newIdSet.should.eql [1, 2, 3]
        done()

      collName = 'userstuffs'
      policy.adapter.send collName, {
        namespace: "test.#{collName}"
        origin: 'delta'
        timestamp: new Date
        _id: 9
        operation: 'set'
        path: '.'
        data:
          _id: 9
          userId: 4
          stuffId: 3
      }

  it 'should retrieve my full set of models', (done) ->
    policy = limit samplePolicy, ['myProfile', 'myStuff', 'visibleUsers']
    #policy.onDebug = logger.grey
    stream = new Stream policy
    stream.register @identity, @receiver, (err) =>

      @collector.payload.length.should.eql 5

      done()
