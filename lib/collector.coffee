{objInclude, find, _, EventEmitter} = require './util'
Client = require './client'
applyOp = require './applyOp'

getEventPath = (root, path) ->
  if path is '.'
    return root
  else
    return "#{root}.#{path}"

class Collector extends EventEmitter

  # connect to server
  # {sessionId?}, {register, onDebug, onError}
  constructor: (options={}) ->
    status = 'waiting'
    @data = {}
    @received = {}
    @identity = options.identity or {}
    @network = options.network or {}
    @debug = options.onDebug or ->
    @onData = options.onData or ->
    @error = options.onError or console.error

    super {
      wildcard: true
      maxListeners: Infinity
    }

    # on register, call user provided register, or connect via websockets
    @onRegister = options.onRegister or (identity, receiver, err) =>
      @client = Client @network
      @client.register identity, receiver, err

    @on 'ready', =>
      @debug 'ready!'
      @status = 'ready'

    @on 'data', (data, event) ->
      @debug 'Sending new data notification!'

      # normalize events and emit specific path changes
      eventName = getEventPath event.root, event.path
      @emit eventName, data, event

      # respond to constructor based listener
      @onData data, event

  register: (done) ->
    done or= ->
    @onRegister @identity, @receive.bind(@), (err) =>
      done err
      if err
        @error {context: 'Stream: Registration failed.', error: err}
      else
        @debug 'Registered with Stream.'

  receive: (name, event) ->
    @lastUpdated = new Date event.timestamp
    @debug 'Received data.', {name, event}

    switch name

      when 'manifest'
        @manifest = event
        @checkReady()

      when 'payload'
        applyOp @data, event
        @emit 'data', @data, event

        if event.origin is 'end payload'
          @received[event.root] = true

        @checkReady()

      when 'delta'
        @ready =>
          applyOp @data, event
          @emit 'data', @data, event

  checkReady: ->
    checkManifest = (received, manifest) ->
      return false unless manifest?
      for name of manifest when name isnt 'timestamp'
        return false unless received[name]
      return true

    ready = checkManifest @received, @manifest

    @debug "Checking if we're ready...", {manifest: @manifest?, allReceived: ready}
    @emit 'ready' if ready

  ready: (done) ->
    if @status is 'ready'
      done()
    else
      @once 'ready', done

  reset: (done) ->
    delete @data[name] for name of @data
    @status = 'loading'
    @ready done

module.exports = Collector
