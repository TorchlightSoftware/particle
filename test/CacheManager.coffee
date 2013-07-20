Relcache = require 'relcache'
logger = require 'ale'

MockAdapter = require '../lib/adapters/mock'
CacheManager = require '../lib/cache/CacheManager'

describe 'CacheManager', ->
  before ->
    @collName = 'users'
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
          name: 'Bob'
          email: 'bob@foo.com'
        ,
          _id: 2
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

  beforeEach ->
    @cm = new CacheManager {@collName, @adapter, @cache}

  afterEach ->
    @cm.destroy()
    @cache.clear()

  it 'should import cache config', (done) ->
    @cm.importCacheConfig {
      userstuffs:
        stuffId: 'stuffs._id'
        userId: 'users._id'
    }, (err) =>
      @cache.get('stuffs._id').should.eql ['1', '2']

      stuff = @cache.follow 1, 'users._id>userstuffs._id>stuffs._id'
      stuff.should.eql [1, 2]
      done()

  it 'should import data sources', (done) ->
    @cm.importDataSources {
      stuff:
        collection: 'stuffs'
        criteria: {_id: 1}
        manifest: true
      me:
        collection: 'users'
        criteria: {'name': 'Bob'}
        manifest: true
    }, (err) =>
      @cache.get('stuffs._id').should.be.empty
      @cache.get('users.name').should.eql ['Bob', 'Jane']
      done()

  it 'should follow a complex path', (done) ->
    @cm.importCacheConfig {
      userstuffs:
        stuffId: 'stuffs._id'
        userId: 'users._id'
      stuffs:
        stuff: 'stuffs.stuff'
    }, (err) =>

      @cm.importDataSources {
        me:
          collection: 'users'
          criteria: {'name': 'Bob'}
          manifest: true
      }, (err) =>

        bobStuff = @cache.follow 'Bob', 'users.name>users._id>userstuffs._id>stuffs._id>stuffs.stuff'
        bobStuff.should.eql ['foo', 'bar', 'baz']

        janeStuff = @cache.follow 'Jane', 'users.name>users._id>userstuffs._id>stuffs._id>stuffs.stuff'
        janeStuff.should.eql ['baz']
        done()
