{Writable} = require 'stream'
logger = require 'ale'
_ = require 'lodash'

{getType} = require '../util'
convertToIdSet = require './convertToIdSet'

class QueryWriter extends Writable
  constructor: ({@adapter, @cacheManager, @identity, @source, @receiver}) ->
    super {objectMode: true}

    @adapter.query {
      collName: @source.collection
      idSet: @_getIdSet()
      select: @source.manifest
    }, (err, @query) =>

      @cacheManager.on "change:#{@source.name}", ->
        @query.update {idSet: @_getIdSet()}

      #@query.on 'data', logger.blue
      @query.pipe @

  _getIdSet: ->
    if @source.criteria
      return convertToIdSet @cacheManager, @identity, @source.collection, @source.criteria
    else
      return undefined

  _write: (event, encoding, done) ->

    # trigger ready status
    if event.origin is 'end payload'
      event.origin = 'payload'
      process.nextTick =>
        @emit 'ready'

    # write to receiver
    @receiver event.origin, event
    done()

  ready: (done) ->
    if @status is 'ready'
      process.nextTick(done)
    else if @status is 'error'
      process.nextTick =>
        done @error
    else
      @once 'ready', done

  destroy: ->
    if @query?
      @query.unpipe @
      delete @query

module.exports = QueryWriter
