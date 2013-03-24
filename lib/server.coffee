{createServerWrapper} = require 'protosock'

server =
  options:
    namespace: 'particle'
    resource: 'default'
    debug: false

  registered: (err) ->
    @ssocket.send
      type: 'registered'
      err: err

  receive: (name, event) ->
    @ssocket.send
      type: 'data'
      name: name
      event: event

  message: (socket, msg) ->
    switch msg.type
      when 'register'
        @register identity, @receive, @registered

  error: (socket, err) ->

  init: (register) ->
    @register = register

module.exports = (options) ->
  createServerWrapper server
