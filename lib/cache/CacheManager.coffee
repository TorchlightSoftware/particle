_ = require 'lodash'
logger = require 'ale'
{EventEmitter} = require 'events'
{focus} = require 'qi'

CacheWriter = require './CacheWriter'

class CacheManager extends EventEmitter

  constructor: ({@adapter, @cache}) ->
    super

    @writers = {}
    @status = 'waiting'
    @on 'ready', =>
      @status = 'ready'

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
      keys = _.without _.keys(source.criteria), '_id'
      unless _.isEmpty keys
        @importKeys source.collection, keys, step()

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
    for w in @writers
      w.destroy()

module.exports = CacheManager
