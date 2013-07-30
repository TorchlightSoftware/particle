should = require 'should'
_ = require 'lodash'
logger = require 'ale'
{EventEmitter} = require 'events'
#{Server, Db, ObjectID} = require 'mongodb'

{Stream} = require '../'
samplePolicy = require '../sample/data/samplePolicy'

limit = (policy, sources) ->
  newPolicy = _.clone policy
  newPolicy.dataSources = _.pick newPolicy.dataSources, sources
  newPolicy

describe 'Stream', ->
  beforeEach ->
    @collector = new EventEmitter
    @collector.history = []
    @collector.on 'receive', (origin, event) =>
      @collector[origin] ?= []
      @collector[origin].push event
    @receiver = @collector.emit.bind(@collector, 'receive')

    @identity =
      userId: 1
      accountId: 1

  it 'should connect source and receiver', (done) ->
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
        _id: 1
        operation: 'set'
        path: '.'
        data: { _id: 1, accountId: 1, name: 'Bob', email: 'bob@foo.com' }
      }
      jane.should.include {
        origin: 'end payload'
        namespace: 'test.users'
        _id: 2
        operation: 'set'
        path: '.'
        data: { _id: 2, accountId: 1, name: 'Jane', email: 'jane@foo.com' }
      }
      done()

  #it 'should connect source and receiver', (done) ->
    #policy = limit samplePolicy, ['visibleUsers']
    ##policy.onDebug = logger.grey
    #stream = new Stream policy
    #stream.register @identity, @receiver, (err) =>

      #@collector.manifest.length.should.eql 1
      #_.keys(@collector.manifest[0]).should.eql ['timestamp', 'visibleUsers']

      #@collector.payload.length.should.eql 2
      #[bob, jane] = @collector.payload
      #bob.should.include {
        #origin: 'payload'
        #namespace: 'test.users'
        #_id: 1
        #operation: 'set'
        #path: '.'
        #data: { _id: 1, accountId: 1, name: 'Bob', email: 'bob@foo.com' }
      #}
      #jane.should.include {
        #origin: 'end payload'
        #namespace: 'test.users'
        #_id: 2
        #operation: 'set'
        #path: '.'
        #data: { _id: 2, accountId: 1, name: 'Jane', email: 'jane@foo.com' }
      #}
      #done()
