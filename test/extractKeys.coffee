should = require 'should'
extractKeys = require '../lib/cache/extractKeys'

describe 'extractKeys', ->
  tests = [
      description: 'filter _id'
      input: {_id: 5}
      output: []
    ,
      description: 'simple keys'
      input: {name: 'Ken'}
      output: ['name']
    ,
      description: 'nested keys'
      input: {$or: {name: 'Ken', country: 'Canada'}}
      output: ['name', 'country']
    ,
      description: 'comparison operator'
      input: {loginCount: {$gte: 10}}
      output: ['loginCount']
    ,
      description: 'mixed'
      input: {name: 'Ken', loginCount: {$gte: 10}}
      output: ['name', 'loginCount']
  ]

  for test in tests
    do (test) ->
      {description, input, output} = test
      it description, ->
        result = extractKeys input
        result.should.eql output
