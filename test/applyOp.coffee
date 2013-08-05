{inspect} = require 'util'
should = require 'should'
applyOp = require '../lib/applyOp'
_ = require 'lodash'
logger = (args...) -> console.log args.map((a) -> if (typeof a) is 'string' then a else inspect a, null, null)...

tests = [
    description: 'path should navigate arrays by id'
    pre:
      users: [
        _id: 5
        name: 'Bob'
        todos: [
          {_id: 5, description: 'take out the trash'}
          {_id: 9, description: 'do the dishes'}
        ]
      ]
    op:
      root: 'users'
      timestamp: new Date
      operation: 'set'
      _id: 5
      path: 'todos[5].description'
      data: 'take over the world'
    post:
      users: [
        _id: 5
        name: 'Bob'
        todos: [
            {_id: 5, description: 'take over the world'}
            {_id: 9, description: 'do the dishes'}
        ]
      ]
  ,
    description: 'path should create a new array element'
    pre:
      users: [
        _id: 5
        name: 'Bob'
        todos: [
        ]
      ]
    op:
      root: 'users'
      timestamp: new Date
      operation: 'set'
      _id: 5
      path: 'todos[5].description'
      data: 'take over the world'
    post:
      users: [
        _id: 5
        name: 'Bob'
        todos: [
          {_id: 5, description: 'take over the world'}
        ]
      ]
  ,
    description: 'path should create a new array'
    pre:
      users: [
        _id: 5
        name: 'Bob'
      ]
    op:
      root: 'users'
      timestamp: new Date
      operation: 'set'
      _id: 5
      path: 'todos[5].description'
      data: 'take over the world'
    post:
      users: [
        _id: 5
        name: 'Bob'
        todos: [
          {_id: 5, description: 'take over the world'}
        ]
      ]
  ,
    description: 'set should create a new record in an existing collection'
    pre: {users: []}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'set'
      _id: 5
      path: '.'
      data: {name: 'Bob'}
    post: {users: [{_id: 5, name: 'Bob'}]}
  ,
    description: 'set should create a new collection and a new record'
    pre: {}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'set'
      _id: 5
      path: '.'
      data: {name: 'Bob'}
    post: {users: [{_id: 5, name: 'Bob'}]}
  ,
    description: 'set should not interfere with existing records'
    pre: {users: [{_id: 6}, {_id: 'nine', face: 'nameless'}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'set'
      _id: 5
      path: '.'
      data: {name: 'Bob'}
    post: {users: [{_id: 6}, {_id: 'nine', face: 'nameless'}, {_id: 5, name: 'Bob'}]}
  ,
    description: 'set should work with arrays'
    pre: {users: [{_id: 6}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'set'
      _id: 6
      path: '.'
      data: {stuff: []}
    post: {users: [{_id: 6, stuff: []}]}
  ,
    description: 'unset should remove a field'
    pre: {users: [{_id: 5, name: 'Bob'}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'unset'
      _id: 5
      path: 'name'
    post: {users: [{_id: 5}]}
  ,
    description: 'unset should remove a record'
    pre: {users: [{_id: 5, name: 'Bob'}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'unset'
      _id: 5
      path: '.'
    post: {users: []}
  ,
    description: 'unset should not create new records'
    pre: {users: []}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'unset'
      _id: 5
      path: 'name'
    post: {users: []}
  ,
    description: 'unset should not create new fields'
    pre: {users: [{_id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'unset'
      _id: 5
      path: 'friends.bob'
    post: {users: [{_id: 5}]}
  ,
    description: 'inc should increment a value'
    pre: {users: [{_id: 5, friends: 1}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'inc'
      _id: 5
      path: 'friends'
    post: {users: [{_id: 5, friends: 2}]}
  ,
    description: 'inc should increment a value by 4'
    pre: {users: [{_id: 5, friends: 1}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'inc'
      _id: 5
      path: 'friends'
      data: 4
    post: {users: [{_id: 5, friends: 5}]}
  ,
    description: 'inc should create a new value'
    pre: {users: [{_id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'inc'
      _id: 5
      path: 'friends'
    post: {users: [{_id: 5, friends: 1}]}
  ,
    description: 'inc should decrement a value'
    pre: {users: [{_id: 5, friends: 0}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'inc'
      _id: 5
      path: 'friends'
      data: -1
    post: {users: [{_id: 5, friends: -1}]}
  ,
    description: 'rename should rename a field'
    pre: {users: [{_id: 5, friends: 0}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'rename'
      _id: 5
      path: 'friends'
      data: 'enemies'
    post: {users: [{_id: 5, enemies: 0}]}
  ,
    description: 'rename a non-existent field should work'
    pre: {users: [{_id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'rename'
      _id: 5
      path: 'friends'
      data: 'enemies'
    post: {users: [{_id: 5, enemies: undefined}]}
  ,
    description: 'rename should overwrite an existing field'
    pre: {users: [{_id: 5, friends: 4, enemies: 8}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'rename'
      _id: 5
      path: 'friends'
      data: 'enemies'
    post: {users: [{_id: 5, enemies: 4}]}
  ,
    description: 'push should add to an array'
    pre: {users: [{_id: 5, friends: []}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'push'
      _id: 5
      path: 'friends'
      data: 'Jim'
    post: {users: [{_id: 5, friends: ['Jim']}]}
  ,
    description: 'push should create an array'
    pre: {users: [{_id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'push'
      _id: 5
      path: 'friends'
      data: 'Jim'
    post: {users: [{_id: 5, friends: ['Jim']}]}
  ,
    description: 'pushAll should add to an array'
    pre: {users: [{_id: 5, friends: []}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'pushAll'
      _id: 5
      path: 'friends'
      data: ['Jim']
    post: {users: [{_id: 5, friends: ['Jim']}]}
  ,
    description: 'pushAll should create an array'
    pre: {users: [{_id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'pushAll'
      _id: 5
      path: 'friends'
      data: ['Jim']
    post: {users: [{_id: 5, friends: ['Jim']}]}
  ,
    description: 'pop should remove an element from the end'
    pre: {users: [{_id: 5, friends: ['Jane', 'Bob']}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'pop'
      _id: 5
      path: 'friends'
    post: {users: [{_id: 5, friends: ['Jane']}]}
  ,
    description: 'pop should remove an element from the beginning'
    pre: {users: [{_id: 5, friends: ['Jane', 'Bob']}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'pop'
      _id: 5
      path: 'friends'
      data: -1
    post: {users: [{_id: 5, friends: ['Bob']}]}
  ,
    description: 'pull should remove an element'
    pre: {users: [{_id: 5, friends: [
      {_id: 9, name: 'Jane'}
      {_id: 10, name: 'Bob'}
    ]}]}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'pull'
      _id: 5
      path: 'friends'
      data: {_id: 9}
    post: {users: [{_id: 5, friends: [
      {_id: 10, name: 'Bob'}
    ]}]}
  ,
    description: 'noop should only create collection'
    pre: {}
    op:
      root: 'users'
      timestamp: new Date
      operation: 'noop'
    post: {users: []}
]

describe 'applyOp', ->

  for test in tests
    do (test) ->
      {pre, op, post, description} = test
      it description, ->
        applyOp pre, op
        #logger 'pre:', pre, '\npost:', post
        pre.should.eql post
