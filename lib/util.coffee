# select versions based on whether we're client or server
if window?
  {EventEmitter2} = require 'EventEmitter2'
  {_} = require './lodash'
else
  {EventEmitter2} = require 'eventemitter2'
  _ = require 'lodash'

module.exports = util =

  # export the selected versions so the rest of the lib can access it
  _: _
  EventEmitter: EventEmitter2

  getType: (obj) -> Object.prototype.toString.call(obj).slice 8, -1

  # check to see if an object contains one or more keys
  objInclude: (target, list) ->
    return false unless util.getType(target) is 'Object'
    keys = switch util.getType(list)
      when 'Array'
        list
      when 'String'
        [list]
      when 'Object'
        Object.keys list
      else
        null
    return false unless keys?

    for name in keys
      return false unless target[name]
    return true

  empty: (obj) ->
    return true unless obj?
    switch util.getType(obj)
      when 'Object'
        return Object.keys(obj).length is 0
      when 'Array', 'String'
        return obj.length is 0
      else
        return false

  contains: (target, test) ->
    _.isEqual target, test, (left, right) ->
      if _.isPlainObject(left) and _.isPlainObject(right)
        newLeft = _.pick left, _.keys right
        return _.isEqual newLeft, right

  indexContaining: (list, test) ->
    for el, index in list
      if util.contains el, test
        return index
    return null

  box: (val) ->
    return [] unless val?
    if util.getType(val) is 'Array'
      val
    else
      [val]
