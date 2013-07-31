Relcache = require 'relcache'
{EventEmitter} = require 'events'

CacheManager = require './cache/CacheManager'
QueryManager = require './query/QueryManager'
Server = require './server'

{empty, _} = require './util'
filterPayload = require './filterPayload'
filterDelta = require './filterDelta'
debugMixin = require './mixins/debug'

class Stream extends EventEmitter
  listeners: []
  policy: {}

  constructor: (policy) ->
    @onDebug = policy.onDebug
    debugMixin.call(@)

    @queryManagers = []

    @policy = policy or {}
    @policy.dataSources or= {}
    for name, def of @policy.dataSources
      def.manifest ?= true
    @policy.identityLookup or= (identity, done) -> done null, identity

    @cache = new Relcache
    @cacheManager = new CacheManager {adapter: @policy.adapter, @cache, @onDebug}
    @cacheManager.importCacheConfig @policy.cache
    @cacheManager.importDataSources @policy.dataSources

    @error = @policy.onError or console.error

  init: (server, options) ->
    @server = Server server, options
    @server.init @register.bind(@)

  register: (identity, receive, done) ->

    @debug 'Registering.'.yellow, {identity}

    # lookup additional identifying information
    @policy.identityLookup identity, (err, finalIdentity) =>
      return done err if err
      _.extend identity, finalIdentity
      @debug 'Completed identity lookup.'.yellow, {err, identity}

      # send a manifest to the client
      manifest = {timestamp: new Date}
      for name, source of @policy.dataSources
        manifest[name] = source.manifest
      receive 'manifest', manifest
      @debug 'Sent manifest, waiting for queries.'.yellow, {manifest}

      qm = new QueryManager {
        adapter: @policy.adapter
        cacheManager: @cacheManager
        identity: identity
        dataSources: @policy.dataSources
        receiver: receive
        onDebug: @onDebug
      }
      @queryManagers.push qm
      qm.init done

  disconnect: ->
    @server?.disconnect()
    @policy?.disconnect()

module.exports = Stream
