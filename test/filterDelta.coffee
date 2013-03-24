should = require 'should'
filterDelta = require '../lib/filterDelta'

updatePassword =
  operation: 'set'
  id: 5
  path: 'password'
  data: 'secret'

updateEmail =
  operation: 'set'
  id: 5
  path: 'email'
  data: 'foo@bar.com'

updateTodo =
  operation: 'set'
  id: 5
  path: 'todos.0.description'
  data: 'take over the world'

updateDocument =
  operation: 'set'
  id: 5
  path: '.'
  data: {email: 'graham@daventry.com'}

updateInvalidDocument =
  operation: 'set'
  id: 5
  path: '.'
  data: {password: 'secret'}

tests = [
    description: 'should pass all items'
    pre: [updatePassword, updateEmail, updateTodo]
    manifest: true
    post: [updatePassword, updateEmail, updateTodo]
  ,
    description: 'should filter items not in the manifest'
    pre: [updatePassword]
    manifest:
      email: true
    post: []
  ,
    description: 'should pass items in the manifest'
    pre: [updatePassword, updateEmail]
    manifest:
      email: true
    post: [updateEmail]
  ,
    description: 'should pass items in an array'
    pre: [updateTodo]
    manifest:
      todos:
        description: true
    post: [updateTodo]
  ,
    description: 'should handle document update'
    pre: [updateDocument]
    manifest:
      email: true
    post: [updateDocument]
  ,
    description: 'should remove invalid fields from document update'
    pre: [updateInvalidDocument]
    manifest:
      email: true
    post: []
]

describe 'filterDelta', ->
  for test in tests
    do (test) ->
      {description, pre, manifest, post} = test
      it description, ->
        result = filterDelta manifest, pre
        should.exist result, 'expected result' if post?
        result.should.eql post if post?
        should.not.exist result unless post?
