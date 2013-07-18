{getType} = require '../util'
logger = require 'ale'
_ = require 'lodash'

flattenKvps = (keypath, data) ->
  kvps = {}

  walk = (keypath, data) ->
    switch getType(data)
      when 'Object'
        for k, v of data when not k.match /_id$/
          subkeys = walk "#{keypath}.#{k}", v
      else
        kvps[keypath] = data

  walk keypath, data
  return kvps

module.exports = (event) ->
  collName = event.namespace?.split('.')[1]

  # extract the id path and create a relationship
  idKey = "#{collName}._id"
  idRel = {}
  idRel[idKey] = event._id

  # root of any operations that will occur
  baseKey = if event.path is '.' then collName else "#{collName}.#{event.path}"

  # list of commands we will append to
  commands = []

  switch event.operation
    when 'set'
      kvps = flattenKvps baseKey, event.data
      commands.push ['set', idKey, event._id, kvps]
    when 'unset'
      cmd = ['unset', idKey, event._id]
      cmd.push baseKey unless event.path is '.'
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
