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
    output.push op if validOp manifest, op

  return output
