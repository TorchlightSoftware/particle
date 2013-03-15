{EventEmitter} = require 'events'
{objInclude, find, box} = require './util'
normalizePayload = require './normalizePayload'
_ = require 'lodash'

class Collector extends EventEmitter

  # connect to server
  # {sessionId?}, {register, onDebug, onError}
  constructor: (options) ->
    status = 'loading'
    @data = {}
    @identity = options.identity or {}
    @debug = options.onDebug or ->
    @error = options.onError or console.error
    throw new Error 'Register argument is required.' unless options.register
    register = options.register # or (identity, receiver, err) -> socket connection

    @on 'ready', =>
      @debug 'ready!'
      @status = 'ready'

    @on 'data', (args...) ->
      @debug 'Sending new data notification!'
      options.onData args... if options.onData

    register @identity, @receive.bind(@), (err) =>
      if err
        @error {context: 'Error: Stream - Could not initiate data transfer.', error: err}
      else
        @debug 'Done loading data.'

  receive: (name, event) ->
    @lastUpdated = new Date event.timestamp
    @debug 'Received data.', {name, event}

    applyOp = ({root, oplist}) =>

      for op in oplist

        # get required params
        {path, id, data, operation} = op

        # get or create document
        node = _.find @data[root], (n) -> n.id is id
        unless node
          node = {id: id}
          @data[root].push node

        if path is '.'
          # rewind target/node so root can be set
          target = @data[root].indexOf node
          node = @data[root]
          data = _.extend data, {id: id}

        else
          # walk down through the target document
          [location..., target] = path.split '.'
          for part in location
            node[part] ?= {} # TODO: maybe do []/{} depending on manifest?
            node = node[part]

        # apply the appropriate change
        @debug "Updating data with '#{operation}'."
        switch operation
          when 'set'
            node[target] = data
          when 'unset'
            delete node[target]
          when 'inc'
            node[target] += data
          when 'rename'
            node[data] = node[target]
            delete node[target]

    switch name

      when 'manifest'
        @manifest = event
        @checkReady()

      when 'payload'
        @data[event.root] = event.data

        # format the data to look like a normal update
        # only tell listeners about it if we actually got data
        nm = normalizePayload event
        if nm.oplist.length > 0
          @emit 'data', @data, nm

        @checkReady()

      when 'delta'
        @ready =>
          applyOp event
          @emit 'data', @data, event


  checkReady: ->
    checkManifest = (data, manifest) ->
      for name of manifest when name isnt 'timestamp'
        return false unless data[name]
      return true

    ready = checkManifest @data, @manifest

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
