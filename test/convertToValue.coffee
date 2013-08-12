should = require 'should'
Relcache = require 'relcache'
logger = require 'torch'

convertToValue = require '../lib/query/convertToValue'

describe 'convertToValue', ->
  before ->
    @cache = new Relcache
    @identity =
      userId: 2
      session:
        accountId: 1

  beforeEach ->
    @cache.set 'users._id', 2,  {'users.name': 'Alice',   'users.country': 'USA',    'users.loginCount': 0}
    @cache.set 'users._id', 5,  {'users.name': 'Ken',     'users.country': 'Mexico', 'users.loginCount': 9}
    @cache.set 'users._id', 7,  {'users.name': 'Bob',     'users.country': 'Canada', 'users.loginCount': 10}

  afterEach ->
    @cache.clear()

  # We're going to get back scalar values if we're provided a primitive or an identity lookup.
  # Otherwise, if it has to go through a cache lookup we'll end up with an array.
  # This should be ok, since convertToIdSet can apparently work just fine with array inputs.
  # See convertToIdSet tests for validation of this.
  tests = [
      description: 'regular value'
      statement: 2
      output: 2
    ,
      description: 'identity lookup'
      statement: '@userId'
      output: 2
    ,
      description: 'nested value'
      statement: '@session.accountId'
      output: 1
    ,
      description: 'non-present identity'
      statement: '@foo'
      output: undefined
    ,
      description: 'regular to cache'
      statement: '2|users._id>users.name'
      output: ['Alice']
    ,
      description: 'identity to cache'
      statement: '@userId|users._id>users.name'
      output: ['Alice']
    ,
      description: 'non-present identity to cache'
      statement: '@foo|users._id>users.name'
      output: []
    ,
      description: 'identity to non-present cache'
      statement: '@userId|foo>users.name'
      output: []
    ,
  ]

  for test in tests
    do (test) ->
      {description, statement, output} = test
      it description, ->
        result = convertToValue @cache, @identity, statement
        if output?
          should.exist result
          result.should.eql output
        else
          should.not.exist result
