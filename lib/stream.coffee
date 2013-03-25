_ = require 'lodash'
{empty} = require './util'
filterPayload = require './filterPayload'
filterDelta = require './filterDelta'
Server = require './server'

class Stream
  listeners: []
  policy: {}

  constructor: (policy) ->

    @policy = policy or {}
    @policy.dataSources or= {}
    @policy.identityLookup or= (identity, done) -> done null, identity

    @debug = policy.onDebug or ->

    @error = @policy.onError or console.error

  init: (server, options) ->
    @server = Server server, options
    @server.init @register.bind(@)

  register: (identity, receive, done) ->

    @debug 'Registering.', {identity}

    # lookup additional identifying information
    @policy.identityLookup identity, (err, finalIdentity) =>
      return done err if err
      _.extend identity, finalIdentity
      @debug 'Completed identity lookup.', {identity, err}

      # send a manifest to the client
      manifest = {timestamp: new Date}
      for name, source of @policy.dataSources
        manifest[name] = source.manifest
      receive 'manifest', manifest
      @debug 'Sent manifest.', {manifest}

      # connect data deltas to their respective collections in the dataRoot
      for name, source of @policy.dataSources

        # close over variables so they stay set in the callbacks
        do (name, source) =>
          {delta, payload, manifest} = source

          # respond with initial data {data, timestamp}
          @debug 'Requesting payload.', {identity}
          payload identity, (err, initialData) =>
            if err
              @error {identity: identity, context: 'Error retrieving payload.', error: err}
            else
              filtered = filterPayload manifest, initialData.data
              event = _.extend {}, initialData, {root: name, data: filtered}
              @debug 'Sent payload.', {event, err}
              receive 'payload', event

          # respond with deltas over time
          delta identity, (change) =>
            filtered = filterDelta manifest, change.oplist
            unless empty filtered
              event = _.extend {}, change, {root: name, oplist: filtered}
              @debug 'Sent delta.', {event}
              receive 'delta', event

      done()

  disconnect: ->
    @server.disconnect() if @server
    @policy.disconnect()

module.exports = Stream
