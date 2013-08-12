_ = require 'lodash'
{EventEmitter} = require 'events'

CacheWriter = require './CacheWriter'
extractKeys = require './extractKeys'
extractDependencies = require './extractDependencies'
readyMixin = require '../mixins/ready'
debugMixin = require '../mixins/debug'

class CacheManager extends EventEmitter

  #{@adapter, @cache, @onDebug}
  constructor: (args) ->
    _.merge @, args
    super
    readyMixin.call(@)
    debugMixin.call(@)

    @writers = {}

    # forward cache events
    @onChange = @emit.bind(@, 'change')
    @cache.on 'change', @onChange
    @on 'change', @debug.bind(@, 'Cache modified.'.red)

    # forward query methods to cache
    @get = @cache.get.bind(@cache)
    @find = @cache.find.bind(@cache)
    @follow = @cache.follow.bind(@cache)

  importKeys: (collName, keys, done) ->
    return process.nextTick(done) if _.isEmpty keys

    @debug 'importing keys into cache:'.red, {collName, keys}
    @status = 'waiting'

    # do we have a writer for that collection?
    if @writers[collName]
      @writers[collName].importKeys keys

    else

      # add a new query
      @writers[collName] = new CacheWriter {collName, @adapter, @cache, @onDebug}
      @writers[collName].importKeys keys
      @writers[collName].on 'ready', @checkReady.bind(@)

    @ready done if done

  importCacheConfig: (config, done) ->
    @status = 'waiting'

    @debug 'Importing cache config:'.red, config
    for collection, mapping of config
      @importKeys collection, mapping

    @ready done if done

  importDataSources: (dataSources, done) ->
    @debug 'Importing data sources:'.red, dataSources

    for name, source of dataSources
      collection = source.collection

      # get keys and deps for finding related cache updates
      keys = extractKeys source.criteria
      deps = extractDependencies source.criteria

      #logger.yellow {criteria: source.criteria, keys, deps}

      # create or update a writer for this collection
      unless _.isEmpty keys
        @status = 'waiting'
        @importKeys collection, keys

      fullKeys = _.map keys, (k) -> "#{collection}.#{k}"

      @debug 'watching keys for datasource'.red, {name, keys, deps, fullKeys}
      do (name, keys, deps, fullKeys) =>

        # forward events that relate to this dataSource
        @on 'change', (event) =>

          # get our targets regardless of if it's an add or remove
          {key, relation, targets} = event
          if relation
            targets = _.keys relation
          else
            targets = _.keys targets

          # identify keys internal to the collection
          matchingKeys = _.intersection fullKeys, targets
          unless _.isEmpty matchingKeys
            return @emit "change:#{name}", event

          # identify external cache lookup dependencies
          else
            #logger.grey 'comparing:'.cyan, {deps, key, targets}
            for dep in deps when (dep[0] is key) and (dep[1] in targets)
              return @emit "change:#{name}", event

          # if nothing is found, ignore the event

    @ready done if done

  checkReady: ->
    status = _.map @writers, 'status'
    ready = _.every status, (s) -> s is 'ready'
    @debug 'Cache Writers ready?'.red, status, ready
    @emit 'ready' if ready

  destroy: ->
    @cache.removeListener 'change', @onChange
    @removeAllListeners()

    for w in @writers
      w.destroy()

module.exports = CacheManager
