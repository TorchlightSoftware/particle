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
  mapping ?= {}

  # extract the id path and create a relationship
  idKey = "#{collName}._id"
  idRel = {}
  idRel[idKey] = event._id

  # helpers to determine whether many-to-many should be used
  getKey = (v, k) -> k
  isLocal = (k) -> k.match(new RegExp "^#{collName}\.")
  isnot = (val) -> not val

  # map to unique key space in relcache
  keymap = (key) ->
    usermapping = mapping[key]
    if usermapping?
      return usermapping
    else
      return "#{collName}.#{key}"

  # list of commands we will append to
  commands = []

  switch event.operation

    when 'set'
      kvps = flattenKvps event.path, event.data, keymap
      locals = _.pick kvps, _.compose(isLocal, getKey)
      remotes = _.pick kvps, _.compose(isnot, isLocal, getKey)

      unless _.isEmpty locals
        commands.push ['set', idKey, event._id, locals]
      unless _.isEmpty remotes
        commands.push ['add', idKey, event._id, remotes]

    when 'unset'
      unless event.path is '.'
        path = keymap(event.path)
        op = if isLocal(path) then 'unset' else 'remove'
      else
        op = 'unset'

      cmd = [op, idKey, event._id]
      cmd.push path if path
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
