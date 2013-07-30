Relcache = require 'relcache'
logger = require 'ale'

CacheManager = require './cache/CacheManager'
QueryManager = require './query/QueryManager'
Server = require './server'

{empty, _} = require './util'
filterPayload = require './filterPayload'
filterDelta = require './filterDelta'

class Stream
  listeners: []
  policy: {}

  constructor: (policy) ->

    @queryManagers = []

    @policy = policy or {}
    @policy.dataSources or= {}
    for name, def of @policy.dataSources
      def.manifest ?= true
    @policy.identityLookup or= (identity, done) -> done null, identity

    @cache = new Relcache
    @cacheManager = new CacheManager {adapter: @policy.adapter, @cache}
    @cacheManager.importCacheConfig @policy.cache
    @cacheManager.importDataSources @policy.dataSources

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
      @debug 'Completed identity lookup.', {err, identity}

      # send a manifest to the client
      manifest = {timestamp: new Date}
      for name, source of @policy.dataSources
        manifest[name] = source.manifest
      receive 'manifest', manifest
      @debug 'Sent manifest.', {manifest}

      inputs = {
        adapter: @policy.adapter
        cacheManager: @cacheManager
        identity: identity
        dataSources: @policy.dataSources
        receiver: receive
      }

      qm = new QueryManager inputs
      @queryManagers.push qm
      qm.ready done

  disconnect: ->
    @server.disconnect() if @server
    @policy.disconnect()

module.exports = Stream
