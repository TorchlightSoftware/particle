_ = require 'lodash'
logger = require 'ale'

module.exports = (cache, identity, statement) ->
  return statement unless _.isString statement
  [base, path] = statement.split '|'

  # lookup identity field if required
  if base.match /^@/
    base = identity[base.slice 1]

  if path
    return cache.follow base, path
  else
    return base
