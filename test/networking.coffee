should = require 'should'
logger = require './helpers/logger'
{getType} = require '../lib/util'
{Collector, Stream} = require '../'
http = require 'http'

randomPort = Math.floor(Math.random() * 1000) + 8000

describe 'network', ->

  before (done) ->
    @server = http.createServer().listen randomPort, done

  afterEach ->
    #@stream.disconnect()

  it 'should serialize/deserialize error in registration', (done) ->
    @stream = new Stream
      identityLookup: (identity, found) ->
        found new Error 'oops'

    @stream.init @server

    collector = new Collector
      #onDebug: logger
      network:
        port: randomPort
        host: 'localhost'

    collector.register (err) ->
      should.exist err
      getType(err).should.eql 'Error'
      err.message.should.eql 'oops'
      should.exist err.stack
      done()

  it 'should return error in payload', (done) ->
    @stream = new Stream
      dataSources:
        stuff:
          manifest: true
          payload: (identity, found) ->
            found new Error 'oops'
          delta: (identity, receiver) ->

      onError: ({identity, context, error}) ->
        getType(error).should.eql 'Error'
        error.message.should.eql 'oops'
        should.exist error.stack
        done()

    @stream.init @server

    collector = new Collector
      #onDebug: logger
      network:
        port: randomPort
        host: 'localhost'

    collector.register ->
