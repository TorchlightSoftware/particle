_ = require 'lodash'
logger = require 'ale'
{EventEmitter} = require 'events'
{focus} = require 'qi'

QueryWriter = require './QueryWriter'
readyMixin = require '../mixins/ready'

class QueryManager extends EventEmitter

  constructor: ({@adapter, @cacheManager, @identity, @dataSources, @receiver}) ->
    super
    readyMixin.call(@)

    @writers = {}

    for name, source of @dataSources
      source = _.merge {}, source, {name}

      #logger.grey 'new QueryWriter:'.cyan, {adapter: @adapter?, cm: @cacheManager?, @identity, source, @receiver}
      @writers[name] = new QueryWriter {@adapter, @cacheManager, @identity, source, @receiver}
      @writers[name].ready @checkReady.bind(@)

  checkReady: ->
    ready = _.every @writers, (w) -> w.status is 'ready'
    @emit 'ready' if ready

  destroy: ->
    for w in @writers
      w.destroy()

module.exports = QueryManager
