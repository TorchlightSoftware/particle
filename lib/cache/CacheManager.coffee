_ = require 'lodash'
logger = require 'ale'
{EventEmitter} = require 'events'
{focus} = require 'qi'

CacheWriter = require './CacheWriter'
extractKeys = require './extractKeys'
extractDependencies = require './extractDependencies'

class CacheManager extends EventEmitter

  constructor: ({@adapter, @cache}) ->
    super

    @writers = {}
    @status = 'waiting'
    @on 'ready', =>
      @status = 'ready'

    # forward cache events
    @onChange = @emit.bind(@, 'change')
    @cache.on 'change', @onChange

    # forward query methods to cache
    @get = @cache.get.bind(@cache)
    @find = @cache.find.bind(@cache)
    @follow = @cache.follow.bind(@cache)

  importKeys: (collName, keys, done) ->
    return process.nextTick(done) if _.isEmpty keys

    @status = 'waiting'

    # do we have a writer for that collection?
    if @writers[collName]
      @writers[collName].importKeys keys

    else

      # add a new query
      @writers[collName] = new CacheWriter {collName, @adapter, @cache}
      @writers[collName].importKeys keys
      @writers[collName].on 'ready', @checkReady.bind(@)

    @ready done if done

  importCacheConfig: (config, done) ->
    @status = 'waiting'

    for collection, mapping of config
      @importKeys collection, mapping

    @ready done if done

  importDataSources: (dataSources, done) ->

    for name, source of dataSources
      collection = source.collection

      # get keys and deps for finding related cache updates
      keys = extractKeys source.criteria
      deps = extractDependencies source.criteria

      #logger.yellow {criteria: source.criteria, keys}

      # create or update a writer for this collection
      unless _.isEmpty keys
        @status = 'waiting'
        @importKeys collection, keys

      fullKeys = _.map keys, (k) -> "#{collection}.#{k}"

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
          for dep in deps when (dep[0] is key) and (dep[1] in targets)
            return @emit "change:#{name}", event

        # if nothing is found, ignore the event

    @ready done if done

  checkReady: ->
    ready = _.every @writers, (w) -> w.status is 'ready'
    @emit 'ready' if ready

  ready: (done) ->
    if @status is 'ready'
      process.nextTick done
    else if @status is 'error'
      process.nextTick =>
        done @error
    else
      @once 'ready', done

  destroy: ->
    @cache.removeListener 'change', @onChange
    @removeAllListeners()

    for w in @writers
      w.destroy()

module.exports = CacheManager
