{createServerWrapper} = require 'protosock'
{getType} = require './util'

serializeError = (err) ->
  if getType(err) is 'Error'
    return {
      __type: 'Error'
      message: err.message
      stack: err.stack
    }
  else
    return err

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
      err: serializeError(err)

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
