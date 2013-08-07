_ = require 'lodash'
MongoWatch = require 'mongo-watch'

#{host, port, db, dbOpts}
watcher = new MongoWatch {db: 'test', format: 'normal'}

samplePolicy = require './samplePolicy'

module.exports = ->
  mwPolicy = samplePolicy()
  _.merge mwPolicy, {
    adapter: watcher
    disconnect: ->
      watcher.stopAll()
  }
