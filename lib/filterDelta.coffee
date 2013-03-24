filterPayload = require './filterPayload'
{empty} = require './util'
_ = require 'lodash'

validOp = (node, op) ->
  for location in op.path.split '.'
    return true if node is true

    if /[0-9]+/.test location
      # do nothing, this is an array

    else if node[location]
      node = node[location]
    else
      return false
  return true

module.exports = (manifest, oplist) ->

  output = []
  for op in oplist

    # handle full document update just like a payload
    if op.path is '.'
      result = _.clone op
      result.data = filterPayload manifest, result.data
      output.push result unless empty result.data

    # otherwise it's valid if the path can be found in the manifest
    else
      output.push op if validOp manifest, op

  return output
