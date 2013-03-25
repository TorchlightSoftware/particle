{createClientWrapper} = require 'protosock'

client =
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
    console.log {err}

  register: (identity, receive, finish) ->
    @ssocket.write
      type: 'register'
      identity: identity

    @onRegistered = finish
    @receive = receive

module.exports = Client = createClientWrapper client
