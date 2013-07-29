_ = require 'lodash'
logger = require 'ale'
{EventEmitter} = require 'events'
{focus} = require 'qi'

QueryWriter = require './QueryWriter'

class QueryManager extends EventEmitter

  constructor: ({@adapter, @cacheManager, @identity, @dataSources, @receiver}) ->
    super

    @writers = {}
    @status = 'waiting'
    @on 'ready', =>
      @status = 'ready'

    for name, source of @dataSources
      source = _.merge {}, source, {name}

      #logger.grey 'new QueryWriter:'.cyan, {adapter: @adapter?, cm: @cacheManager?, @identity, source, @receiver}
      @writers[name] = new QueryWriter {@adapter, @cacheManager, @identity, source, @receiver}
      @writers[name].ready @checkReady.bind(@)

  checkReady: ->
    ready = _.every @writers, (w) -> w.status is 'ready'
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

module.exports = QueryManager
