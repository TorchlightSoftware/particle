MongoWatch = require 'mongo-watch'
watcher = new MongoWatch {format: 'normal'}

module.exports = (collection) ->

  #onDebug: console.log

  identityLookup: (identity, done) ->
    done null, {accountId: 1}

  dataSources:

    users:
      manifest: # limit what fields should be allowed
        email: true
        todo: {list: true}

      payload: # get initial data for this collection
        (identity, done) ->
          collection.find().toArray (err, data) ->
            done err, {data: data, timestamp: new Date}

      delta: # wire up deltas for this collection
        (identity, listener) ->
          watcher.watch "test.users", listener

  disconnect: ->
    watcher.stopAll()
