{inspect} = require 'util'
should = require 'should'
applyOp = require '../lib/applyOp'
_ = require 'lodash'
logger = (args...) -> console.log args.map((a) -> if (typeof a) is 'string' then a else inspect a, null, null)...

tests = [
    description: 'path should navigate arrays by id'
    pre:
      users: [
        id: 5
        name: 'Bob'
        todos: [
          {id: 5, description: 'take out the trash'}
          {id: 9, description: 'do the dishes'}
        ]
      ]
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'set'
        id: 5
        path: 'todos[5].description'
        data: 'take over the world'
      ]
    post:
      users: [
        id: 5
        name: 'Bob'
        todos: [
            {id: 5, description: 'take over the world'}
            {id: 9, description: 'do the dishes'}
        ]
      ]
  ,
    description: 'path should create a new array element'
    pre:
      users: [
        id: 5
        name: 'Bob'
        todos: [
        ]
      ]
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'set'
        id: 5
        path: 'todos[5].description'
        data: 'take over the world'
      ]
    post:
      users: [
        id: 5
        name: 'Bob'
        todos: [
          {id: 5, description: 'take over the world'}
        ]
      ]
  ,
    description: 'path should create a new array'
    pre:
      users: [
        id: 5
        name: 'Bob'
      ]
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'set'
        id: 5
        path: 'todos[5].description'
        data: 'take over the world'
      ]
    post:
      users: [
        id: 5
        name: 'Bob'
        todos: [
          {id: 5, description: 'take over the world'}
        ]
      ]
  ,
    description: 'set should create a new record in an existing collection'
    pre: {users: []}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'set'
        id: 5
        path: '.'
        data: {name: 'Bob'}
      ]
    post: {users: [{id: 5, name: 'Bob'}]}
  ,
    description: 'set should create a new collection and a new record'
    pre: {}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'set'
        id: 5
        path: '.'
        data: {name: 'Bob'}
      ]
    post: {users: [{id: 5, name: 'Bob'}]}
  ,
    description: 'set should not interfere with existing records'
    pre: {users: [{id: 6}, {id: 'nine', face: 'nameless'}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'set'
        id: 5
        path: '.'
        data: {name: 'Bob'}
      ]
    post: {users: [{id: 6}, {id: 'nine', face: 'nameless'}, {id: 5, name: 'Bob'}]}
  ,
    description: 'set should work with arrays'
    pre: {users: [{id: 6}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'set'
        id: 6
        path: '.'
        data: {stuff: []}
      ]
    post: {users: [{id: 6, stuff: []}]}
  ,
    description: 'unset should remove a field'
    pre: {users: [{id: 5, name: 'Bob'}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'unset'
        id: 5
        path: 'name'
      ]
    post: {users: [{id: 5}]}
  ,
    description: 'unset should remove a record'
    pre: {users: [{id: 5, name: 'Bob'}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'unset'
        id: 5
        path: '.'
      ]
    post: {users: []}
  ,
    description: 'unset should not create new records'
    pre: {users: []}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'unset'
        id: 5
        path: 'name'
      ]
    post: {users: []}
  ,
    description: 'unset should not create new fields'
    pre: {users: [{id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'unset'
        id: 5
        path: 'friends.bob'
      ]
    post: {users: [{id: 5}]}
  ,
    description: 'inc should increment a value'
    pre: {users: [{id: 5, friends: 1}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'inc'
        id: 5
        path: 'friends'
      ]
    post: {users: [{id: 5, friends: 2}]}
  ,
    description: 'inc should increment a value by 4'
    pre: {users: [{id: 5, friends: 1}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'inc'
        id: 5
        path: 'friends'
        data: 4
      ]
    post: {users: [{id: 5, friends: 5}]}
  ,
    description: 'inc should create a new value'
    pre: {users: [{id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'inc'
        id: 5
        path: 'friends'
      ]
    post: {users: [{id: 5, friends: 1}]}
  ,
    description: 'inc should decrement a value'
    pre: {users: [{id: 5, friends: 0}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'inc'
        id: 5
        path: 'friends'
        data: -1
      ]
    post: {users: [{id: 5, friends: -1}]}
  ,
    description: 'rename should rename a field'
    pre: {users: [{id: 5, friends: 0}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'rename'
        id: 5
        path: 'friends'
        data: 'enemies'
      ]
    post: {users: [{id: 5, enemies: 0}]}
  ,
    description: 'rename a non-existent field should work'
    pre: {users: [{id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'rename'
        id: 5
        path: 'friends'
        data: 'enemies'
      ]
    post: {users: [{id: 5, enemies: undefined}]}
  ,
    description: 'rename should overwrite an existing field'
    pre: {users: [{id: 5, friends: 4, enemies: 8}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'rename'
        id: 5
        path: 'friends'
        data: 'enemies'
      ]
    post: {users: [{id: 5, enemies: 4}]}
  ,
    description: 'push should add to an array'
    pre: {users: [{id: 5, friends: []}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'push'
        id: 5
        path: 'friends'
        data: 'Jim'
      ]
    post: {users: [{id: 5, friends: ['Jim']}]}
  ,
    description: 'push should create an array'
    pre: {users: [{id: 5}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'push'
        id: 5
        path: 'friends'
        data: 'Jim'
      ]
    post: {users: [{id: 5, friends: ['Jim']}]}
  ,
    description: 'pop should remove an element from the end'
    pre: {users: [{id: 5, friends: ['Jane', 'Bob']}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'pop'
        id: 5
        path: 'friends'
      ]
    post: {users: [{id: 5, friends: ['Jane']}]}
  ,
    description: 'pop should remove an element from the beginning'
    pre: {users: [{id: 5, friends: ['Jane', 'Bob']}]}
    op:
      root: 'users'
      timestamp: new Date
      oplist: [
        operation: 'pop'
        id: 5
        path: 'friends'
        data: -1
      ]
    post: {users: [{id: 5, friends: ['Bob']}]}
]

describe 'applyOp', ->

  for test in tests
    do (test) ->
      {pre, op, post, description} = test
      it description, ->
        applyOp pre, op
        #logger 'pre:', pre, '\npost:', post
        pre.should.eql post
