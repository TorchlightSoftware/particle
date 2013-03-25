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
    #console.log "Server sending 'registered' to client"
    socket.write
      type: 'registered'
      err: err

  receive: (socket, name, event) ->
    #console.log "Server sending data to client. name: '#{name}', event:", event
    socket.write
      type: 'data'
      name: name
      event: event

  message: (socket, msg) ->
    switch msg.type
      when 'register'
        @register msg.identity, @receive.bind(@, socket), @registered.bind(@, socket)

  error: (socket, err) ->
    console.log {err}

  disconnect: ->
    for conn in connections
      conn.close()

module.exports = Server = createServerWrapper server, {foo: 1}
