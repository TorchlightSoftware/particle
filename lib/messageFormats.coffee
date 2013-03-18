JaySchema = require 'jayschema'
jsv = new JaySchema

module.exports =

  # stream formats
  streamInPolicy: (policy) ->
    validator = {
      type: 'object'
      required: ['dataSources']
      properties:

        onDebug:
          type: 'function'

        identityLookup:
          type: 'function'

        dataSources:
          type: 'object'

          additionalProperties:
            type: 'object'
            properties:

              manifest: # limit what fields should be allowed
                '$ref': '#/definitions/manifestNode'

              payload: # get initial data for this collection
                type: 'function'
                required: true

              delta: # wire up deltas for this collection
                type: 'function'
                required: true

        disconnect:
          type: 'function'

      definitions:
        manifestNode:
          type: ['object', 'boolean']
          additionalProperties: #TODO: change to regex, disallow []
            '$ref': '#/definitions/manifestNode'
    }

    jsv.validate policy, validator


  streamOutManifest: (manifest) ->

  streamInDelta: (delta) ->
    # array elements should be objects
    # array elements should have ids
    # path should be '.' or 'foo' or 'foo.bar' or 'foo[5]'
    # each path section can only contain one set of []

  streamOutDelta: (delta) ->

  streamInPayload: (payload) ->
    # array elements should be objects
    # array elements should have ids

  streamOutPayload: (payload) ->

  # collector formats
  collectorData: (manifest, data) ->
  collectorEvent: (manifest, event) ->
