{Writable} = require 'stream'
_ = require 'lodash'

{getType} = require '../util'
convertToIdSet = require './convertToIdSet'
readyMixin = require '../mixins/ready'
debugMixin = require '../mixins/debug'

class QueryWriter extends Writable

  #{@adapter, @cacheManager, @identity, @sourceName, @source, @receiver}
  constructor: (args) ->
    _.merge @, args
    super {objectMode: true}
    readyMixin.call(@)
    debugMixin.call(@)

    @debug "'#{@sourceName}' waiting for cache manager...".blue

    @cacheManager.ready =>

      idSet = @_getIdSet()

      query = {
        collName: @source.collection
        idSet
        select: @source.manifest
      }

      @debug "'#{@sourceName}' running...".blue, query
      @adapter.query query, (err, @query) =>

        @cacheManager.on "change:#{@sourceName}", (event) =>
          newIdSet = @_getIdSet()
          @debug 'updating query:'.blue, {@source, newIdSet}
          @query?.update {newIdSet}

        @query.pipe @

  _getIdSet: ->
    if @source.criteria
      return convertToIdSet @cacheManager, @identity, @source.collection, @source.criteria
    else
      return undefined

  _write: (event, encoding, done) ->

    # tell the receiver what source this is for
    event.root = @sourceName

    # trigger ready status
    if event.origin is 'end payload'
      @debug "got end payload for '#{event.root}'".blue
      origin = 'payload'
      process.nextTick =>
        @emit 'ready'

    else
      origin = event.origin

    # write to receiver
    @debug 'sending event:'.blue, {origin, event}
    @receiver origin, event
    done()

  destroy: ->
    if @query?
      @query.unpipe @
      delete @query

module.exports = QueryWriter
