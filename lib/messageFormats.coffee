#jsv = require('JSV').JSV.createEnvironment 'json-schema-draft-03'
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
          additionalProperties:
            '$ref': '#/definitions/manifestNode'
    }

    jsv.validate policy, validator


  streamOutManifest: (manifest) ->

  streamInDelta: (delta) ->
  streamOutDelta: (delta) ->

  streamInPayload: (payload) ->
  streamOutPayload: (payload) ->

  # collector formats
  collectorData: (manifest, data) ->
  collectorEvent: (manifest, event) ->
