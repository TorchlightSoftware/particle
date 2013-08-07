http = require 'http'
connect = require 'connect'
logger = require 'torch'
{join} = require 'path'

{Stream} = require '../..'
samplePolicy = require('../data/samplePolicy')()

# serve a static directory and allow connections from anywhere
app = connect()
app.use (req, res, next) ->
  res.setHeader "Access-Control-Allow-Origin", "*"
  next()
app.use connect.static join __dirname, '../public'

port = 4042

# listen on port
server = http.createServer(app).listen port, ->

  #samplePolicy.onDebug = logger.grey
  stream = new Stream samplePolicy
  stream.init server
  stream.ready ->
    logger.white stream.cache._cache
    counter = 0

    collName = 'users'
    sendDelta = ->
      data =
        namespace: "test.#{collName}"
        origin: 'delta'
        timestamp: new Date
        _id: 4
        operation: 'set'
        path: 'stuffCount'
        data: ++counter
      samplePolicy.adapter.send collName, data

    setInterval sendDelta, 1000

  console.log "started server at http://localhost:#{port}/test.html"
