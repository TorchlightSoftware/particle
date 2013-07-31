{focus} = require 'qi'
{EventEmitter} = require 'events'
Relcache = require 'relcache'
logger = require 'torch'

CacheManager = require '../lib/cache/CacheManager'
QueryManager = require '../lib/query/QueryManager'
MockAdapter = require '../lib/adapters/mock'

describe 'QueryManager', ->
  before ->
    @collName = 'users'
    @adapter = new MockAdapter {
      users: [
          _id: 1
          name: 'Bob'
      ]
      stuffs: [
          _id: 1
          userId: 1
          stuff: ['foo', 'bar']
        ,
          _id: 2
          userId: 1
          stuff: ['baz']
      ]
    }

    # mock receiver
    @collector = new EventEmitter
    @collector.history = []
    @collector.on 'receive', (origin, event) =>
      @collector.history.push event
    @receiver = @collector.emit.bind(@collector, 'receive')

    # prepare state
    @identity =
      userId: 1
    @cache = new Relcache
    @cacheConfig =
      stuffs: {userId: 'users._id'}
    @dataSources =
      allUsers:
        collection: 'users'
        manifest: true

  beforeEach (done) ->
    @cacheManager = new CacheManager {@collName, @adapter, @cache}

    step = focus =>
      @queryManager = new QueryManager {@adapter, @cacheManager, @dataSources, @identity, @receiver}
      @queryManager.init done

    @cacheManager.importDataSources @dataSources, step()
    @cacheManager.importCacheConfig @cacheConfig, step()

  afterEach ->
    @cacheManager.destroy()
    @queryManager.destroy()
    @cache.clear()

  it 'should get all users', (done) ->
    @collector.history.length.should.eql 1
    done()
