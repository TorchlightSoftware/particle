should = require 'should'
logger = require 'torch'

convertToIdSet = require '../lib/query/convertToIdSet'
Relcache = require 'relcache'
relcache = new Relcache

describe 'convertToIdSet', ->

  # we assume that all indexed fields are densely populated:
  # they should have a definition even if the value is null or undefined
  relcache.set 'users._id', 2,  {'users.name': 'Alice',   'users.country': 'USA',    'users.loginCount': 0}
  relcache.set 'users._id', 5,  {'users.name': 'Ken',     'users.country': 'Mexico', 'users.loginCount': 9}
  relcache.set 'users._id', 7,  {'users.name': 'Bob',     'users.country': 'Canada', 'users.loginCount': 10}
  relcache.set 'users._id', 9,  {'users.name': 'Jane',    'users.country': 'Canada', 'users.loginCount': 7}
  relcache.set 'users._id', 13, {'users.name': 'Max',     'users.country': 'USA',    'users.loginCount': 16}
  relcache.set 'users._id', 19, {'users.name': 'Shannon', 'users.country': 'USA',    'users.loginCount': 12}

  tests = [
      description: 'default empty set'
      query: undefined
      output: undefined
    ,
      description: 'key not found'
      query: {foo: 1}
      output: []
    ,
      description: 'value not found'
      query: {name: 'Billy'}
      output: []
    ,
      description: 'get by _id'
      query: {_id: 5}
      output: [5]
    ,
      description: 'simple keys'
      query: {name: 'Ken'}
      output: [5]
    ,
      description: 'array value'
      query: {name: ['Ken']}
      output: [5]
    ,
      description: 'empty array value'
      query: {name: []}
      output: []
    ,
      description: 'negation'
      query: {name: {$ne: 'Ken'}}
      output: [2, 7, 9, 13, 19]
        #nin: [5]
    ,
      description: 'negation of array'
      query: {name: {$ne: ['Ken']}}
      output: [2, 7, 9, 13, 19]
        #nin: [5]
    ,
      description: 'nested keys'
      query: {$or: {name: 'Ken', country: 'Canada'}}
      output: [5, 7, 9]
    ,
      description: 'comparison operator'
      query: {loginCount: {$gte: 10}}
      output: [7, 19, 13]
    ,
      description: 'comparison not found'
      query: {loginCount: {$gte: 50}}
      output: []
    ,
      description: "'and' reduced to empty set"
      query: {$and: {name: 'Ken', loginCount: {$gte: 10}}}
      #output: and: [{in: [5]}, {in: 7, 19, 13}]
      #output: and: in: []
      output: []
    ,
      description: "root 'and' behavior"
      query: {$and: {name: 'Ken', loginCount: {$gte: 9}}}
      output: [5]
    ,
      description: 'remove exception'
      query: {$and: {loginCount: {$gte: 9}, name: {$ne: 'Ken'}}}
      output: [7, 19, 13]
    ,
      description: 'identity field'
      query: {name: '@name'}
      output: [5]
    ,
      description: 'cache lookup'
      query: {_id: '@name|users.name>users._id'}
      output: [5]
  ]

  identity =
    userId: 5
    name: 'Ken'
  collection = 'users'

  for test in tests
    do (test) ->
      {description, query, output} = test
      it description, ->
        result = convertToIdSet relcache, identity, collection, query
        if output?
          should.exist result
          result.should.eql output
        else
          should.not.exist result
