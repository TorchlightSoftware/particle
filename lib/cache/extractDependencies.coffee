{getType} = require '../util'
_ = require 'lodash'

getDeps = (statement) ->
  return [] unless _.isString statement
  [base, path] = statement.split '|'

  if path?
    path = path.split '>'
    if path.length > 1
      deps = []
      for k, index in path
        rel = path[index+1]
        if rel?
          deps.push [k, rel]
      return deps

  return []

module.exports = (query) ->
  return [] unless getType(query) is 'Object'

  deps = []

  walk = (obj) ->
    for k, v of obj
      if k.match /^\$/ # recurse if it's a mongo op
        walk v
      else
        deps.push getDeps(v)...

  walk query
  return deps
