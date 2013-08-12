_ = require 'lodash'

module.exports = (cache, identity, statement) ->
  return statement unless _.isString statement
  [base, path] = statement.split '|'

  # lookup identity field if required
  if base.match /^@/
    key = base.slice 1
    parts = key.split '.'
    value = identity
    for p in parts
      value = value[p]
    base = value

  if path
    return cache.follow base, path
  else
    return base
