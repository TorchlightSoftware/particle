{createClientWrapper} = require 'protosock'

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
        @onRegistered msg.err
      when 'data'
        @receive msg.name, msg.event

  error: (socket, err) ->
    console.log 'client err:', {err}

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
