{getType} = require '../util'
logger = require 'ale'
_ = require 'lodash'

flattenKvps = (keypath, data, keymap) ->
  kvps = {}

  walk = (keypath, data) ->
    switch getType(data)
      when 'Object'
        for k, v of data when not k.match /_id$/
          subpath = if keypath is '.' then k else "#{keypath}.#{k}"
          subkeys = walk subpath, v
      else
        target = keymap(keypath)
        kvps[target] = data

  walk keypath, data
  return kvps

module.exports = (event, mapping) ->
  collName = event.namespace?.split('.')[1]

  # extract the id path and create a relationship
  idKey = "#{collName}._id"
  idRel = {}
  idRel[idKey] = event._id

  # map to unique key space in relcache
  if mapping
    keymap = (key) ->
      mapping[key]
  else
    keymap = (key) ->
      "#{collName}.#{key}"

  # list of commands we will append to
  commands = []

  switch event.operation
    when 'set'
      kvps = flattenKvps event.path, event.data, keymap
      commands.push ['set', idKey, event._id, kvps]
    when 'unset'
      cmd = ['unset', idKey, event._id]
      cmd.push keymap(event.path) unless event.path is '.'
      commands.push cmd
    else
      logger.red 'Particle Cache received unsupported operation:', event
    #when 'inc'
    #when 'rename'
    #when 'push'
    #when 'pushAll'
    #when 'pop'
    #when 'pull'

  return commands
