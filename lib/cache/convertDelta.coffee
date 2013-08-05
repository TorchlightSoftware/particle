{getType} = require '../util'
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
        if target?
          kvps[target] = data

  walk keypath, data
  return kvps

# Intertwining responsibilites seem to be a major source of complexity here.
# Perhaps this can be split out into a pipeline of transformations, rather than occuring all at once?
# e.g: flattenKvps -> applyMapping -> splitLocalRemote -> filterKeys
module.exports = (event, keys, mapping, onError) ->
  onError ?= ->
  collName = event.namespace?.split('.')[1]
  mapping ?= {}
  keys ?= []

  # extract the id path and create a relationship
  idKey = "#{collName}._id"
  idRel = {}
  idRel[idKey] = event._id

  # map to unique key space in relcache
  keymap = (key) ->
    usermapping = mapping[key]
    if usermapping?
      return usermapping
    else if key in keys
      return "#{collName}.#{key}"

  # list of commands we will append to
  commands = []

  switch event.operation

    when 'set'
      kvps = flattenKvps event.path, event.data, keymap
      unless _.isEmpty kvps
        commands.push ['set', idKey, event._id, kvps]

    when 'unset'
      cmd = ['unset', idKey, event._id]
      unless event.path is '.'
        target = keymap(event.path)
        return [] unless target?
        cmd.push target
      commands.push cmd

    when 'noop'

    else
      onError 'Particle Cache received unsupported operation:'.red, event

    #when 'inc'
    #when 'rename'
    #when 'push'
    #when 'pushAll'
    #when 'pop'
    #when 'pull'

  return commands
