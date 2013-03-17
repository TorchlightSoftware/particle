MongoWatch = require 'mongo-watch'
watcher = new MongoWatch {format: 'normal'}
{inspect} = require 'util'
logger = (args...) -> console.log args.map((a) -> if (typeof a) is 'string' then a else inspect a, null, null)...

module.exports = (collection) ->

  #onDebug: logger

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
            data.forEach (d) ->
              d.id = d._id.toString()
              delete d._id

            done err, {data: data, timestamp: new Date}

      delta: # wire up deltas for this collection
        (identity, listener) ->
          watcher.watch "test.users", listener

  disconnect: ->
    watcher.stopAll()
