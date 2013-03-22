{getType} = require './util'
_ = require 'lodash'

module.exports = walk = (manifest, payload) ->

  #console.log {manifest, payload}
  return payload if manifest is true

  switch getType(payload)

    when 'Object'
      copy = {}
      for key, value of payload
        if manifest[key]
          result = walk manifest[key], value
          copy[key] = result unless result is undefined
      return copy

    when 'Array'
      copy = for value in payload
        walk manifest, value
      return _.without copy, undefined

    else
      return undefined
