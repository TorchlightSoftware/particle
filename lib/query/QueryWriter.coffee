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

    @cacheManager.ready =>

      idSet = @_getIdSet()
      @debug 'initial idSet:'.blue, idSet
      if _.isArray(idSet) and _.isEmpty(idSet)
        @emit 'ready'

      @adapter.query {
        collName: @source.collection
        idSet
        select: @source.manifest
      }, (err, @query) =>

        @cacheManager.on "change:#{@sourceName}", (event) =>
          newIdSet = @_getIdSet()
          @debug 'userIds'.cyan, @cacheManager.get 'users.accountId', 1
          @debug 'accountId'.cyan, @cacheManager.get 'users._id', 3
          @debug 'updating query:'.blue, {@source, newIdSet}
          @query?.update {newIdSet}

        @query.pipe @

  _getIdSet: ->
    if @source.criteria
      return convertToIdSet @cacheManager, @identity, @source.collection, @source.criteria
    else
      return undefined

  _write: (event, encoding, done) ->

    # trigger ready status
    if event.origin is 'end payload'
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
