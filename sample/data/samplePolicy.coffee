MockAdapter = require '../../lib/adapters/mock'
mockSourceData = require './mockSourceData'

module.exports = ->

  adapter: new MockAdapter mockSourceData

  # Normal use case, use mongo-watch to obtain query streams.
  #adapter: new require('MongoWatch')

  #onDebug: console.log

  # Identity Lookup, performed once upon registration.
  #identityLookup: (identity, done) ->
    #done null, identity

  # Cache Config, used to alias many-to-many lookups or otherwise force caching of fields
  cacheConfig:
    userstuffs:
      userId: 'users._id'
      stuffId: 'stuffs._id'

  # Data Sources, the data each connected client will have access to.  Any fields used in
  # the criteria will be automatically cached.
  dataSources:
    myProfile:
      collection: 'users' # the source collection (in mongo or other adapter)
      criteria: {_id: '@userId'} # limit which records come back
      manifest: true # limit which fields come back
    myStuff:
      collection: 'stuffs'
      criteria: {_id: '@userId|users._id>userstuffs._id>stuffs._id'}
      manifest: true
    visibleUsers:
      collection: 'users'
      criteria: {accountId: '@accountId'}
      manifest:
        name: true
        _id: true
    notFound:
      collection: 'users'
      criteria: {notFound: true}
      manifest: true
    allUsers:
      collection: 'users'
      criteria: undefined
      manifest: true
