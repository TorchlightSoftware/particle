_ = require 'lodash'
{EventEmitter} = require 'events'

QueryWriter = require './QueryWriter'
readyMixin = require '../mixins/ready'
debugMixin = require '../mixins/debug'

class QueryManager extends EventEmitter

  #{@adapter, @cacheManager, @identity, @dataSources, @receiver, @onDebug}
  constructor: (args) ->
    super
    _.merge @, args
    readyMixin.call(@)
    debugMixin.call(@)

    @writers = {}

  init: (done) ->

    for name, source of @dataSources
      source = _.merge {}, source, {name}

      @writers[name] = new QueryWriter {@adapter, @cacheManager, @identity, sourceName: name, source, @receiver, @onDebug}
      @writers[name].ready @checkReady.bind(@)

    @debug "Registration waiting for payloads from #{_.keys(@dataSources).length} queries.".magenta
    @ready done if done
    @ready =>
      @debug "Registration completed.".magenta

  checkReady: ->
    ready = _.every @writers, (w) -> w.status is 'ready'
    @emit 'ready' if ready

  destroy: ->
    for w in @writers
      w.destroy()

module.exports = QueryManager
