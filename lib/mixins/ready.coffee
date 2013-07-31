module.exports = ->
  @status = 'waiting'

  @on 'ready', =>
    @status = 'ready' unless @status is 'error'

  @on 'error', (err) =>
    @error = err
    @status = 'error'

  @onError = (args...) ->
    @emit 'error', args...

  @ready = (done) ->
    if @status is 'ready'
      process.nextTick(done)
    else if @status is 'error'
      process.nextTick =>
        done @error
    else
      @once 'ready', done
