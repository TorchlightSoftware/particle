_ = require 'lodash'
logger = require 'ale'
{EventEmitter} = require 'events'
{focus} = require 'qi'

CacheWriter = require './CacheWriter'
extractKeys = require './extractKeys'

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
    done ?= ->
    return process.nextTick(done) if _.isEmpty keys

    @status = 'waiting'

    # do we have a writer for that collection?
    if @writers[collName]
      @writers[collName].importKeys keys, done

    else

      # add a new query
      @writers[collName] = new CacheWriter {collName, @adapter, @cache}
      @writers[collName].importKeys keys, done
      @writers[collName].ready @checkReady.bind(@)

  importCacheConfig: (config, done) ->
    step = focus done

    for collection, mapping of config
      @importKeys collection, mapping, step()

  importDataSources: (dataSources, done) ->
    step = focus done

    for name, source of dataSources
      collection = source.collection
      keys = extractKeys source.criteria
      unless _.isEmpty keys
        @importKeys collection, keys, step()

        fullKeys = _.map keys, (k) -> "#{collection}.#{k}"
        @on 'change', (event) =>

          # get our targets regardless of if it's an add or remove
          {relation, targets} = event
          if relation
            targets = _.keys relation
          else
            targets = _.keys targets

          matchingKeys = _.intersection fullKeys, targets
          unless _.isEmpty matchingKeys
            @emit "change:#{name}", event

  checkReady: ->
    ready = true
    for collName, w of @writers
      ready = false unless w.ready
    @emit 'ready' if ready

  ready: (done) ->
    if @status is 'ready'
      done()
    else if @status is 'error'
      done @error
    else
      @once 'ready', done

  destroy: ->
    @cache.removeListener 'change', @onChange
    @removeAllListeners()

    for w in @writers
      w.destroy()

module.exports = CacheManager
