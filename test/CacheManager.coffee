should = require 'should'
Relcache = require 'relcache'
logger = require 'torch'
{sample} = require 'ale'

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
        ,
          _id: 3
          stuff: ['ang']
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
      @cm.get('stuffs._id').should.eql ['1', '2']

      stuff = @cm.follow 1, 'users._id>userstuffs._id>stuffs._id'
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
      @cm.get('stuffs._id').should.be.empty
      @cm.get('users.name').should.eql ['Bob', 'Jane']
      done()

  it 'should watch data sources', (done) ->
    @cm.importDataSources {
      me:
        collection: 'users'
        criteria: {'name': 'Bob'}
        manifest: true
    }, (err) =>

      # listen for an event on our source
      @cm.once 'change:me', (event) =>
        event.should.eql {
          op: 'remove',
          key: 'users._id',
          value: 1,
          relation: {'users.name': undefined}
        }
        done()

      # send a change to our source collection
      @adapter.send 'users', {
        timestamp: new Date
        namespace: 'test.users'
        operation: 'set'
        _id: 1
        path: 'name'
        data: 'Bobby'
      }

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

        bobStuff = @cm.follow 'Bob', 'users.name>users._id>userstuffs._id>stuffs._id>stuffs.stuff'
        bobStuff.should.eql ['foo', 'bar', 'baz']

        janeStuff = @cm.follow 'Jane', 'users.name>users._id>userstuffs._id>stuffs._id>stuffs.stuff'
        janeStuff.should.eql ['baz']
        done()

  it 'should emit updates for dependent record changes', (done) ->
    @cm.importCacheConfig {
      userstuffs:
        stuffId: 'stuffs._id'
        userId: 'users._id'
      stuffs:
        stuff: 'stuffs.stuff'
    }, (err) =>

      @cm.importDataSources {
        myStuff:
          collection: 'stuffs'
          criteria: {_id: '@userId|users._id>userstuffs._id>stuffs._id'}
          manifest: true
      }, (err) =>

        sample @cm, 'change:myStuff', 2, (err, events) ->
          [[addId], [addReverse]] = events
          should.exist addId
          should.exist addReverse

          addId.should.eql {
            op: 'add',
            key: 'userstuffs._id',
            value: 4,
            relation: {'users._id': 1, 'stuffs._id': 3}
          }
          addReverse.should.eql {
            op: 'add',
            key: 'users._id',
            value: 1,
            relation: {'userstuffs._id': 4}
          }
          done()

        collName = 'userstuffs'
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
