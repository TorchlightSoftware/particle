_ = require 'lodash'

class Stream
  listeners: []
  policy: {}

  constructor: (policy) ->

    @policy = policy or {}
    @policy.dataSources or= {}
    @policy.identityLookup or= (identity, done) -> done null, identity

    @debug = policy.onDebug or ->

    @error = @policy.onError or console.error

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
          {delta, payload} = source

          # respond with initial data {data, timestamp}
          payload identity, (err, initialData) =>
            if err
              @error {identity: identity, context: 'Error retrieving payload.', error: err}
            else
              event = _.extend {}, initialData, {root: name}
              @debug 'Sent payload.', {event, err}
              receive 'payload', event

          # respond with deltas over time
          delta identity, (change) =>
            event = _.extend {}, change, {root: name}
            @debug 'Sent delta.', {event}
            receive 'delta', event

      done()

  disconnect: ->
    @policy.disconnect()

module.exports = Stream
