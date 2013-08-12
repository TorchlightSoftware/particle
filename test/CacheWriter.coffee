Relcache = require 'relcache'
logger = require 'torch'
{sample} = require 'ale'

MockAdapter = require '../lib/adapters/mock'
CacheWriter = require '../lib/cache/CacheWriter'

updateJane = {
  timestamp: new Date
  namespace: 'test.users'
  operation: 'set'
  _id: 2
  path: 'email'
  data: 'jane@bar.com'
}

accountIds = [
    origin: 'end payload'
    timestamp: new Date
    namespace: 'test.users'
    operation: 'set'
    _id: 1
    path: 'accountId'
    data: 1
  ,
    origin: 'end payload'
    timestamp: new Date
    namespace: 'test.users'
    operation: 'set'
    _id: 2
    path: 'accountId'
    data: 1
]

describe 'CacheWriter', ->
  before ->
    @collName = 'users'
    @adapter = new MockAdapter {
      users: [
          accountId: 1
          _id: 1
          name: 'Bob'
          email: 'bob@foo.com'
        ,
          accountId: 1
          _id: 2
          name: 'Jane'
          email: 'jane@foo.com'
      ]
    }
    @cache = new Relcache

  beforeEach ->
    @cache?.clear()
    @writer = new CacheWriter {@collName, @adapter, @cache}

  afterEach ->
    @writer.destroy()
    @cache.clear()

  it 'should import keys', (done) ->
    @writer.importKeys ['name', 'email'], (err) =>
      name = @cache.get 'users._id', 1, 'users.name'
      name.should.eql 'Bob'

      email = @cache.get 'users._id', 1, 'users.email'
      email.should.eql 'bob@foo.com'

      _id = @cache.get 'users.name', 'Bob', 'users._id'
      _id.should.eql [1]
      done()

  it 'cache should update me when keys change', (done) ->


    @writer.importKeys ['name', 'email'], (err) =>

      # wait for removal of old values
      sample @cache, 'change', 2, =>

        @cache.once 'change', ({op, key, value, relation}) =>
          op.should.eql 'add'
          key.should.eql 'users._id'
          value.should.eql 2
          relation.should.eql {'users.email': 'jane@bar.com'}
          done()

      @adapter.send 'users', updateJane

  it 'should alias a field', (done) ->
    @writer.importKeys {accountId: 'accounts._id'}, (err) =>

      bob = @cache.get 'users._id', 1
      bob.should.eql {'accounts._id': 1}

      account = @cache.get 'accounts._id', 1
      account.should.eql {'users._id': [1, 2]}
      done()

  it 'should notify me when ready', (done) ->
    @writer.importKeys ['name', 'email'], (err) =>
    @writer.ready ->
      done()

  it 'should only create one query', (done) ->
    @writer.importKeys ['name', 'email'], (err) =>
      query = @writer.query
      @writer.importKeys ['accountId'], (err) =>
        query.should.eql @writer.query
        @writer.keys.should.eql ['name', 'email', 'accountId']
        done()

      # adapter doesn't respond to updates, must mock send
      for accId in accountIds
        @adapter.send 'users', accId
