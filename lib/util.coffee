_ = require 'lodash'

module.exports = util =

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
