{createServerWrapper} = require 'protosock'

connections = []

server =
  options:
    namespace: 'particle'
    resource: 'default'
    debug: true

  init: (register) ->
    @register = register

  connect: (socket) ->
    connections.push socket

  registered: (socket, err) ->
    socket.write
      type: 'registered'
      err: err

  receive: (socket, name, event) ->
    socket.write
      type: 'data'
      name: name
      event: event

  message: (socket, msg) ->
    switch msg.type
      when 'register'
        @register msg.identity, @receive.bind(@, socket), @registered.bind(@, socket)

  error: (socket, err) ->
    console.log 'server err:', err?.stack or err

  disconnect: ->
    for conn in connections
      conn.close()

module.exports = Server = createServerWrapper server, {foo: 1}
