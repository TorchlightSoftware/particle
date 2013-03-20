should = require 'should'
util = require '../lib/util'

tests = [
    description: 'should detect an exact match'
    target:
      id: 5
    test:
      id: 5
    out: true
  ,
    description: 'should ignore extra data'
    target:
      id: 5
      name: 'Fred'
    test:
      id: 5
    out: true
  ,
    description: 'should detect a mismatch'
    target:
      id: 5
      name: 'Fred'
    test:
      id: 4
    out: false
  ,
    description: 'should detect a missing field'
    target:
      name: 'Fred'
    test:
      id: 5
    out: false
]

describe 'contains', ->
  for test in tests
    do (test) ->
      {description, target, test, out} = test
      it description, ->
        result = util.contains target, test
        result.should.eql out
