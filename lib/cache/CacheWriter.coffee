{Writable} = require 'stream'
{getType} = require '../util'
_ = require 'lodash'

convertDelta = require './convertDelta'
readyMixin = require '../mixins/ready'
debugMixin = require '../mixins/debug'

convertToSelect = (keys) ->
  select = {}
  for key in keys
    select[key] = 1
  return select

class CacheWriter extends Writable

  #{@collName, @adapter, @cache, @onDebug}
  constructor: (args) ->
    _.merge @, args
    super {objectMode: true}
    readyMixin.call(@)
    debugMixin.call(@)

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
      @debug 'Cache updating query:'.red, {@collName, newSelect}
      @query.update {newSelect}

    else

      # add a new query
      @keys = keys
      select = convertToSelect keys
      @debug 'Cache requesting query:'.red, {@collName, select}
      @adapter.query {@collName, select}, (err, @query) =>
        if err
          @emit 'error', err
        else
          @emit 'got query'
          @query.pipe @

    @ready done if done?

  _write: (event, encoding, done) ->
    #@debug '\nconverting:'.red, event, '\nwith:'.red, {@keys, @mapping}
    commands = convertDelta event, @keys, @mapping, @onError
    @debug '\nmodifying cache:'.red, {commands}

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
