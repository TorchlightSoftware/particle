module.exports = {
  stuffs: [
      _id: 1
      stuff: ['foo', 'bar']
    ,
      _id: 2
      stuff: ['baz']
    ,
      _id: 3
      stuff: ['ang']
  ]
  users: [
      _id: 4
      accountId: 1
      name: 'Bob'
      email: 'bob@foo.com'
    ,
      _id: 5
      accountId: 1
      name: 'Jane'
      email: 'jane@foo.com'
  ]
  userstuffs: [
      _id: 6
      userId: 4
      stuffId: 1
    ,
      _id: 7
      userId: 4
      stuffId: 2
    ,
      _id: 8
      userId: 5
      stuffId: 2
  ]
}
