module.exports = [
    origin: 'end payload'
    namespace: 'test.users'
    timestamp: new Date
    _id: 1
    operation: 'set'
    path: '.'
    data: { _id: 1, accountId: 1, name: 'Bob', email: 'bob@foo.com' }
    root: 'myProfile'
  ,
    origin: 'payload'
    namespace: 'test.stuffs'
    timestamp: new Date
    _id: 1
    operation: 'set'
    path: '.'
    data: { _id: 1, stuff: [ 'foo', 'bar' ] }
    root: 'myStuff'
  ,
    origin: 'end payload'
    namespace: 'test.stuffs'
    timestamp: new Date
    _id: 2
    operation: 'set'
    path: '.'
    data: { _id: 2, stuff: [ 'baz' ] }
    root: 'myStuff'
  ,
    origin: 'payload'
    namespace: 'test.users'
    timestamp: new Date
    _id: 1
    operation: 'set'
    path: '.'
    data: { _id: 1, name: 'Bob' }
    root: 'visibleUsers'
  ,
    origin: 'end payload'
    namespace: 'test.users'
    timestamp: new Date
    _id: 2
    operation: 'set'
    path: '.'
    data: { _id: 2, name: 'Jane' }
    root: 'visibleUsers'
]
