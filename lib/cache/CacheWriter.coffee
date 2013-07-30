{Writable} = require 'stream'
{getType} = require '../util'
logger = require 'ale'
_ = require 'lodash'

convertDelta = require './convertDelta'
readyMixin = require '../mixins/ready'

convertToSelect = (keys) ->
  select = {}
  for key in keys
    select[key] = 1
  return select

class CacheWriter extends Writable
  constructor: ({@collName, @adapter, @cache}) ->
    super {objectMode: true}
    readyMixin.call(@)

    @query = null

  importKeys: (keys, done) ->

    # extract field mapping if present
    if getType(keys) is 'Object'
      if @mapping?
        _.merge @mapping, keys
      else
        @mapping = keys
      keys = _.keys @mapping

    return process.nextTick(done) if _.isEmpty(keys) and done?
    @status = 'waiting'

    # do we have a running query?
    if @query?
      newKeys = _.union @keys, keys
      newSelect = convertToSelect newKeys
      @keys = newKeys
      @query.update {newSelect}

    else

      # add a new query
      @keys = keys
      newSelect = convertToSelect keys
      @adapter.query {@collName, newSelect}, (err, @query) =>
        if err
          @emit 'error', err
        else
          @query.pipe @

    @ready done if done?

  _write: (event, encoding, done) ->
    #logger.grey '\nconverting:'.cyan, event, '\nwith:'.cyan, {@keys, @mapping}
    commands = convertDelta event, @keys, @mapping
    #logger.grey '\ncalling:'.cyan, {commands}

    for c in commands
      [command, args...] = c
      @cache[command] args...

    # if end payload, set ready status
    @emit 'ready' if event.origin is 'end payload'
    done()

  destroy: ->
    if @query?
      @query.unpipe @
      delete @query

module.exports = CacheWriter
