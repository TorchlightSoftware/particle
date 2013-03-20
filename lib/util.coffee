_ = require 'lodash'

module.exports = util =

  getType: (obj) -> Object.prototype.toString.call(obj).slice 8, -1

  # compares an object's keys to an array, string or another object's keys
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

  contains: (target, test) ->
    _.isEqual target, test, (left, right) ->
      if _.isPlainObject(left) and _.isPlainObject(right)
        newLeft = _.pick left, _.keys right
        return _.isEqual newLeft, right
