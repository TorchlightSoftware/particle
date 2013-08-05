convertDelta = require '../lib/cache/convertDelta'

describe 'convertDelta', ->
  tests = [
      description: 'insert record'
      delta:
        timestamp: new Date
        namespace: 'test.users'
        operation: 'set'
        _id: 5
        path: '.'
        data:
          name: 'Bob'
          _id: 5
        origin: 'payload'
      keys: ['name']
      commands: [
        ['set', 'users._id', 5, {'users.name': 'Bob'}]
      ]
    ,
      description: 'should not insert without keys'
      delta:
        timestamp: new Date
        namespace: 'test.users'
        operation: 'set'
        _id: 5
        path: '.'
        data:
          name: 'Bob'
          _id: 5
        origin: 'payload'
      commands: []
    ,
      description: 'keys should limit insert'
      delta:
        timestamp: new Date
        namespace: 'test.users'
        operation: 'set'
        _id: 5
        path: '.'
        data:
          name: 'Bob'
          email: 'bob@foo.com'
          _id: 5
        origin: 'payload'
      keys: ['name']
      commands: [
        ['set', 'users._id', 5, {'users.name': 'Bob'}]
      ]
    ,
      description: 'keys should limit unset'
      delta:
        timestamp: new Date
        namespace: 'test.users'
        operation: 'unset'
        _id: 5
        path: 'name'
        origin: 'delta'
      keys: []
      commands: []
    ,
      description: 'update field'
      delta:
        timestamp: new Date
        namespace: 'test.users'
        operation: 'set'
        _id: 5
        path: 'name'
        data: 'Bobby'
        origin: 'delta'
      keys: ['name']
      commands: [
        ['set', 'users._id', 5, {'users.name': 'Bobby'}]
      ]
    ,
      description: 'unset field'
      delta:
        timestamp: new Date
        namespace: 'test.users'
        operation: 'unset'
        _id: 5
        path: 'name'
        origin: 'delta'
      keys: ['name']
      commands: [
        ['unset', 'users._id', 5, 'users.name']
      ]
    ,
      description: 'unset record'
      delta:
        timestamp: new Date
        namespace: 'test.users'
        operation: 'unset'
        _id: 5
        path: '.'
        origin: 'delta'
      commands: [
        ['unset', 'users._id', 5]
      ]
    ,
      description: 'insert record with mapping'
      delta:
        timestamp: new Date
        namespace: 'test.chatsessions'
        operation: 'set'
        _id: 5
        path: '.'
        data:
          sessionId: 1
          chatId: 2
        origin: 'delta'
      mapping:
        'sessionId': 'sessions._id'
        'chatId': 'chats._id'
      commands: [
        ['set', 'chatsessions._id', 5, {'sessions._id': 1, 'chats._id': 2}]
      ]
    ,
      description: 'unset field with mapping'
      delta:
        timestamp: new Date
        namespace: 'test.chatsessions'
        operation: 'unset'
        _id: 5
        path: 'sessionId'
        origin: 'delta'
      mapping:
        'sessionId': 'sessions._id'
        'chatId': 'chats._id'
      commands: [
        ['unset', 'chatsessions._id', 5, 'sessions._id']
      ]
    ,
      description: 'noop'
      delta:
        timestamp: new Date
        namespace: 'test.chats'
        operation: 'noop'
        origin: 'end payload'
      commands: []
  ]

  for test in tests
    do (test) ->
      {delta, keys, mapping, commands, description} = test
      it description, ->
        result = convertDelta delta, keys, mapping
        result.should.eql commands
