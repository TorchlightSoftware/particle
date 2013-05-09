http = require 'http'
connect = require 'connect'
logger = require '../../test/helpers/logger'
{Stream} = require '../..'
{join} = require 'path'

# serve a static directory and allow connections from anywhere
app = connect()
app.use (req, res, next) ->
  res.setHeader "Access-Control-Allow-Origin", "*"
  next()
app.use connect.static join __dirname, '../public'

port = 4042

# listen on port
server = http.createServer(app).listen port, ->

  stream = new Stream
    onDebug: logger

    dataSources:

      users:

        payload: # get initial data for this collection
          (identity, done) ->
            done null, {data: [], timestamp: new Date}

        delta: # wire up deltas for this collection
          (identity, listener) ->
            counter = 0

            sendDelta = ->
              data =
                root: 'users'
                timestamp: new Date
                oplist: [
                  operation: 'set'
                  id: 5
                  path: 'todoCount'
                  data: counter++
                ]
              listener data

            setInterval sendDelta, 1000

  stream.init server
  console.log "started server at http://localhost:#{port}/test.html"
