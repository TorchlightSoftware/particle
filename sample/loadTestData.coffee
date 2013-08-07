_ = require 'lodash'
{MongoClient, ObjectID} = require 'mongodb'
async = require 'async'
logger = require 'torch'

dbOpts = {w: 1, journal: true}

#idMap = {}
#getId = (_id) ->
  #idMap[_id] ?= new ObjectID
  #return idMap[_id]

#convertAllIds = (records) ->
  #records.map (r) ->
    #newId = {_id: getId(r._id)}
    #_.merge {}, r, newId

module.exports = (data, done) ->
  MongoClient.connect 'mongodb://localhost:27017/test', dbOpts, (err, client) ->
    done err if err

    collNames = _.keys(data)
    async.map collNames, ((name, next) ->

      client.collection name, (err, collection) ->
        next err if err

        #converted = convertAllIds data[name]
        #logger.white 'inserting:', converted
        collection.insert data[name], next

    ), done
