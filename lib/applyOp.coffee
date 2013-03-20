_ = require 'lodash'
removers = ['unset']
{indexContaining} = require './util'

module.exports = (dataRoot, {root, oplist}) =>

  # create the collection if it doesn't exist
  dataRoot[root] or= []

  for op in oplist

    # get required params
    {path, id, data, operation} = op

    # get or create document
    node = _.find dataRoot[root], (n) -> n.id is id
    unless node

      # create the doc unless it's a removal op
      if operation in removers
        return
      else
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

        arraySpec = part.match(/\[([0-9+])\]/)
        if arraySpec
          [spec, arrayIndex] = arraySpec
          arrayIndex = parseInt arrayIndex
          part = part.replace spec, ''

        # be forgiving and create non-existent nodes unless it's a removal op
        unless node[part]?
          if operation in removers
            return
          else
            node[part] = if arrayIndex then [] else {}

        # walk to the next node
        node = node[part]

        # if we have an array component, find the appropriate item and walk to it
        if arrayIndex
          subDoc = _.find node, (item) -> item.id is arrayIndex

          # if we can't find the subDoc, create it
          unless subDoc?
            if operation in removers
              return
            else
              subDoc = {id: arrayIndex}
              node.push subDoc

          # walk to the subdoc
          node = subDoc

    # apply the appropriate change
    switch operation
      when 'set'
        node[target] = data
      when 'unset'
        delete node[target]
      when 'inc'
        node[target] = (node[target] or 0) + (data or 1)
      when 'rename'
        node[data] = node[target]
        delete node[target]
      when 'push'
        node[target] or= []
        node[target].push data
      when 'pop'
        if data is -1
          node[target].splice 0, 1
        else
          node[target].splice -1, 1
      when 'pull'
        index = indexContaining node[target], data
        node[target].splice index, 1 if index?
