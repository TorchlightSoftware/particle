MongoWatch = require 'mongo-watch'
watcher = new MongoWatch {format: 'normal'}
{inspect} = require 'util'
logger = require '../test/helpers/logger'

module.exports = (collection, manifest) ->

  #onDebug: logger

  identityLookup: (identity, done) ->
    done null, {accountId: 1}

  dataSources:

    users:

      # limit what fields should be allowed
      manifest: manifest

      payload: # get initial data for this collection
        (identity, done) ->
          collection.find().toArray (err, data) ->
            data.forEach (d) ->
              d.id = d._id.toString()
              delete d._id

            done err, {data: data, timestamp: new Date}

      delta: # wire up deltas for this collection
        (identity, listener) ->
          watcher.watch "test.users", listener

  disconnect: ->
    watcher.stopAll()
