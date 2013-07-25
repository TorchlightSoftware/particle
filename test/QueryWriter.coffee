Relcache = require 'relcache'
logger = require 'ale'
{EventEmitter} = require 'events'

MockAdapter = require '../lib/adapters/mock'
CacheManager = require '../lib/cache/CacheManager'
QueryWriter = require '../lib/query/QueryWriter'

describe 'QueryWriter', ->
  before ->
    @adapter = new MockAdapter {
      stuffs: [
          _id: 1
          stuff: ['foo', 'bar']
        ,
          _id: 2
          stuff: ['baz']
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
    @cache = new Relcache

    @dataSources =
      myProfile:
        collection: 'users'
        criteria: {_id: '@userId'}
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
    @cacheManager = new CacheManager {@adapter, @cache}
    @cacheManager.importDataSources @dataSources, done

  afterEach ->
    @qw.destroy() if @qw?
    @cache.clear()
    @collector.history = []

  it 'should filter a query by _id', (done) ->
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      source: @dataSources.myProfile
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 1
      @collector.history[0].should.include {
        operation: 'set'
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
      source: @dataSources.visibleUsers
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 2
      @collector.history[0].should.include {
        operation: 'set'
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
      source: @dataSources.notFound
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 0
      done()

  it 'should call ready if source criteria is undefined', (done) ->
    @qw = new QueryWriter {
      @adapter
      @cacheManager
      @identity
      source: @dataSources.allUsers
      @receiver
    }
    @qw.ready =>
      @collector.history.length.should.eql 2
      done()
