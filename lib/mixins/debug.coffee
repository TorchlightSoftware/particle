module.exports = ->
  if @onDebug
    @on 'debug', @onDebug

  @debug = (args...) ->
    @emit 'debug', args...
