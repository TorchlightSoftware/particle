{createClientWrapper} = require 'protosock'

deserializeError = (err) ->
  if err?.__type is 'Error'
    newErr = new Error err.message
    newErr.stack = err.stack
    return newErr
  else
    return err

queued = []

client =
  start: ->
    @status = 'waiting'

  connect: (socket) ->
    @status = 'ready'

    # This is a work around for not having an EventEmitter.
    # I could add one in but not sure if it's worth it.
    for q in queued
      q()
    queued = []

  options:
    namespace: 'particle'
    resource: 'default'
    debug: false

  message: (socket, msg) ->
    switch msg.type
      when 'registered'
        @onRegistered deserializeError(msg.err)
      when 'data'
        @receive msg.name, msg.event

  error: (socket, err) ->
    console.log 'Particle client error:', {err: deserializeError(err)}

  ready: (done) ->
    if @status is 'ready'
      done()
    else
      queued.push done

  register: (identity, receive, finish) ->
    @ready =>
      @ssocket.write
        type: 'register'
        identity: identity

      @onRegistered = finish
      @receive = receive

module.exports = Client = createClientWrapper client
