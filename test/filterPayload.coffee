should = require 'should'
filterPayload = require '../lib/filterPayload'

todoUser =
  email: 'foo@bar.com'
  todos: [
    {id: 5, description: 'take out the trash'}
    {id: 6, description: '???'}
    {id: 42, description: 'take over the world'}
    {id: 43, description: 'profit'}
  ]

tests = [
    description: 'should filter items not in the manifest'
    pre: todoUser
    manifest:
      email: true
    post:
      email: 'foo@bar.com'
  ,
    description: 'should filter items from an array'
    pre: todoUser
    manifest:
      email: true
      todos:
        description: true
    post:
      email: 'foo@bar.com'
      todos: [
        {description: 'take out the trash'}
        {description: '???'}
        {description: 'take over the world'}
        {description: 'profit'}
      ]
  ,
    description: 'should accept the entire document'
    pre: todoUser
    manifest: true
    post: todoUser
  ,
    description: 'should filter a scalar when an object is expected'
    pre: 'foo'
    manifest:
      something: true
    post: undefined
  ,
    description: 'should filter a scalar list when an object is expected'
    pre: ['foo', 'bar', 'baz']
    manifest:
      something: true
    post: []
]

describe 'filterPayload', ->
  for test in tests
    do (test) ->
      {description, pre, manifest, post} = test
      it description, ->
        result = filterPayload manifest, pre
        should.exist result, 'expected result' if post?
        result.should.eql post if post?
        should.not.exist result unless post?
