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
      commands: [
        ['set', 'users._id', 5, {'users.name': 'Bob'}]
      ]
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
        ['add', 'chatsessions._id', 5, {'sessions._id': 1, 'chats._id': 2}]
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
        ['remove', 'chatsessions._id', 5, 'sessions._id']
      ]
  ]

  for test in tests
    do (test) ->
      {delta, mapping, commands, description} = test
      it description, ->
        result = convertDelta delta, mapping
        result.should.eql commands
