Relcache = require 'relcache'
logger = require 'torch'
{focus} = require 'qi'
{sample} = require 'ale'
{EventEmitter} = require 'events'
_ = require 'lodash'

MockAdapter = require '../lib/adapters/mock'
CacheManager = require '../lib/cache/CacheManager'
QueryWriter = require '../lib/query/QueryWriter'

describe 'QueryWriter', ->
  before ->
    @data = {
      stuffs: [
          _id: 1
          stuff: ['foo', 'bar']
        ,
          _id: 2
          stuff: ['baz']
        ,
          _id: 3
          stuff: ['ang']
      ]
      users: [
          _id: 1
          accountId: 1
          name: 'Bob'
          email: 'bob@foo.com'
        ,
          _id: 2
          accountId: 1
          name: 'Jane'
          email: 'jane@foo.com'
      ]
      userstuffs: [
          _id: 1
          userId: 1
          stuffId: 1
        ,
          _id: 2
          userId: 1
          stuffId: 2
        ,
          _id: 3
          userId: 2
          stuffId: 2
      ]
    }
    @adapter = new MockAdapter @data
    @cache = new Relcache

    @cacheConfig =
      userstuffs:
        userId: 'users._id'
        stuffId: 'stuffs._id'

    @dataSources =
      myProfile:
        collection: 'users'
        criteria: {_id: '@userId'}
        manifest: true
      myStuff:
        collection: 'stuffs'
        criteria: {_id: '@userId|users._id>userstuffs._id>stuffs._id'}
        manifest: true
      visibleUsers:
        collection: 'users'
        criteria: {accountId: '@accountId'}
        manifest: true
      notFound:
        collection: 'users'
        criteria: {notFound: true}
        manifest: true
      allUsers:
        collection: 'users'
        criteria: undefined
        manifest: true

    @identity =
      userId: 1
      name: 'Bob'
      accountId: 1

    # a mock collector that we can monitor
    @collector = new EventEmitter
    @collector.history = []
    @collector.on 'receive', (origin, event) =>
      @collector.history.push event
    @receiver = @collector.emit.bind(@collector, 'receive')

  beforeEach (done) ->
    step = focus done
    @cacheManager = new CacheManager {@adapter, @cache}
    @cacheManager.importCacheConfig @cacheConfig, step()
    @cacheManager.importDataSources @dataSources, step()

  afterEach ->
    @qw.destroy() if @qw?
    @cache.clear()
    @collector.history = []

  it 'should filter a query by _id', (done) ->
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      sourceName: 'myProfile'
      source: @dataSources.myProfile
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 1
      @collector.history[0].should.include {
        operation: 'set'
        root: 'myProfile'
        _id: 1
        path: '.'
        data:
          _id: 1
          accountId: 1
          name: 'Bob'
          email: 'bob@foo.com'
      }
      done()

  it 'should filter a query by cached field', (done) ->
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      sourceName: 'visibleUsers'
      source: @dataSources.visibleUsers
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 2
      @collector.history[0].should.include {
        operation: 'set'
        root: 'visibleUsers'
        _id: 1
        path: '.'
        data:
          _id: 1
          accountId: 1
          name: 'Bob'
          email: 'bob@foo.com'
      }
      @collector.history[1].should.include {
        operation: 'set'
        root: 'visibleUsers'
        _id: 2
        path: '.'
        data:
          _id: 2
          accountId: 1
          name: 'Jane'
          email: 'jane@foo.com'
      }
      done()

  it 'should call ready if idSet is empty', (done) ->
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      sourceName: 'notFound'
      source: @dataSources.notFound
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 1
      @collector.history[0].should.include {
        origin: 'end payload'
        operation: 'noop'
      }
      done()

  it 'should call ready if source criteria is undefined', (done) ->
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      sourceName: 'allUsers'
      source: @dataSources.allUsers
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 2
      done()

  it 'should filter on relationship', (done) ->
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      sourceName: 'myStuff'
      source: @dataSources.myStuff
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 2
      data = _.map @collector.history, 'data'
      data.should.eql @data.stuffs.slice 0, 2
      done()

  it 'should update on relationship add', (done) ->
    sourceName = 'myStuff'
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      sourceName
      source: @dataSources[sourceName]
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 2

      collName = 'userstuffs'
      sample @adapter, "stuffs:receivedUpdate", 3, (err, events) ->
        [[add1], [add2], [add3]] = events

        add1.newIdSet.should.eql [1, 2, 3]
        add2.newIdSet.should.eql [1, 2, 3]
        add3.newIdSet.should.eql [1, 2, 3]
        done()

      @adapter.send collName, {
        namespace: "test.#{collName}"
        timestamp: new Date
        _id: 4
        operation: 'set'
        path: '.'
        data:
          _id: 4
          userId: 1
          stuffId: 3
      }

  it 'should update on relationship remove', (done) ->
    sourceName = 'myStuff'
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      sourceName
      source: @dataSources[sourceName]
      @receiver
      #onDebug: logger.grey
    }
    @qw.ready =>
      @collector.history.length.should.eql 2
      #logger.yellow @collector.history

      collName = 'userstuffs'
      sample @adapter, "stuffs:receivedUpdate", 3, (err, events) ->
        [[rem1], [rem2], [rem3]] = events
        #logger.white events

        rem1.newIdSet.should.eql [1]
        rem2.newIdSet.should.eql [1]
        rem3.newIdSet.should.eql [1]
        done()

      @adapter.send collName, {
        namespace: "test.#{collName}"
        timestamp: new Date
        _id: 2
        operation: 'unset'
        path: '.'
      }
