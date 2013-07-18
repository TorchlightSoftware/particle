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
  ]

  for test in tests
    do (test) ->
      {delta, commands, description} = test
      it description, ->
        result = convertDelta delta
        result.should.eql commands
