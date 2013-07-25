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
  ,
    description: 'should not bust on string'
    target:
      name: 'Fred'
    test: 'foo'
    out: false
  ,
    description: 'should not bust on null'
    target:
      name: 'Fred'
    test: null
    out: false
]

describe 'contains', ->
  for test in tests
    do (test) ->
      {description, target, test, out} = test
      it description, ->
        result = util.contains target, test
        result.should.eql out

idcTests = [
    description: 'should find a record by ID'
    list: [
      {id: 5, name: 'Bob'}
    ]
    test: {id: 5}
    out: 0
  ,
    description: 'should find a record among peers'
    list: [
      {id: 5, name: 'Bob'}
      {id: 6, name: 'Sally'}
      {id: 7, name: 'Jenny'}
    ]
    test: {id: 6}
    out: 1
]

describe 'indexContaining', ->
  for test in idcTests
    do (test) ->
      {description, list, test, out} = test
      it description, ->
        result = util.indexContaining list, test
        (result is out).should.eql true

describe 'box', ->

  tests = [
      description: 'empty array'
      input: []
      expected: []
    ,
      description: 'undefined'
      input: undefined
      expected: []
    ,
      description: 'null'
      input: null
      expected: []
    ,
      description: 'empty object'
      input: {}
      expected: [{}]
    ,
      description: 'number'
      input: 1
      expected: [1]
    ,
      description: 'string'
      input: 'foo'
      expected: ['foo']
  ]

  for test in tests
    do (test) ->
      {description, input, expected} = test
      it description, ->
        result = util.box input
        result.should.eql expected
