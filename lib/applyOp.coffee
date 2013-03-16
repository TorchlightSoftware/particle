_ = require 'lodash'

module.exports = (dataRoot, {root, oplist}) =>

  for op in oplist

    # get required params
    {path, id, data, operation} = op

    # get or create document
    node = _.find dataRoot[root], (n) -> n.id is id
    unless node
      node = {id: id}
      dataRoot[root].push node

    if path is '.'
      # rewind target/node so root can be set
      target = dataRoot[root].indexOf node
      node = dataRoot[root]
      data = _.extend data, {id: id}

    else
      # walk down through the target document
      [location..., target] = path.split '.'
      for part in location
        node[part] ?= {} # TODO: maybe do []/{} depending on manifest?
        node = node[part]

    # apply the appropriate change
    switch operation
      when 'set'
        node[target] = data
      when 'unset'
        delete node[target]
      when 'inc'
        node[target] += data
      when 'rename'
        node[data] = node[target]
        delete node[target]
