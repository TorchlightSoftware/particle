{Writable} = require 'stream'
logger = require 'ale'
_ = require 'lodash'

{getType} = require '../util'
convertToIdSet = require './convertToIdSet'
readyMixin = require '../mixins/ready'

class QueryWriter extends Writable
  constructor: ({@adapter, @cacheManager, @identity, @sourceName, @source, @receiver}) ->
    super {objectMode: true}
    readyMixin.call(@)

    @cacheManager.ready =>

      idSet = @_getIdSet()
      if _.isArray(idSet) and _.isEmpty(idSet)
        @emit 'ready'

      @adapter.query {
        collName: @source.collection
        idSet
        select: @source.manifest
      }, (err, @query) =>

        @cacheManager.on "change:#{@sourceName}", (event) =>
          @query?.update {newIdSet: @_getIdSet()}

        @query.pipe @

  _getIdSet: ->
    if @source.criteria
      return convertToIdSet @cacheManager, @identity, @source.collection, @source.criteria
    else
      return undefined

  _write: (event, encoding, done) ->
    #logger.grey 'received write:'.cyan, event

    # trigger ready status
    if event.origin is 'end payload'
      origin = 'payload'
      process.nextTick =>
        @emit 'ready'

    else
      origin = event.origin

    # write to receiver
    @receiver origin, event
    done()

  destroy: ->
    if @query?
      @query.unpipe @
      delete @query

module.exports = QueryWriter
