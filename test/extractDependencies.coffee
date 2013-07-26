should = require 'should'
extractDependencies = require '../lib/cache/extractDependencies'

describe 'extractDependencies', ->
  tests = [
      description: 'non string'
      criteria: {_id: 5}
      output: []
    ,
      description: 'no dependencies'
      criteria: {_id: "@userId"}
      output: []
    ,
      description: 'single step path'
      criteria: {_id: "5|users._id>userstuffs._id"}
      output: [
        ['users._id', 'userstuffs._id']
      ]
    ,
      description: 'multiple step path'
      criteria: {_id: "@userId|users._id>userstuffs._id>stuffs._id"}
      output: [
        ['users._id', 'userstuffs._id']
        ['userstuffs._id', 'stuffs._id']
      ]
  ]

  for test in tests
    do (test) ->
      {description, criteria, output} = test
      it description, ->
        result = extractDependencies criteria
        result.should.eql output
