module.exports = (oplist) ->

  (identity, receive, finish) ->

    # send manifest
    receive 'manifest', {
      users:
        email: true
        address:
          state: true
          zip: true
    }

    # send payload
    receive 'payload', {
      root: 'users'
      timestamp: new Date
      data: [
        id: 5
        email: 'graham@daventry.com'
        address:
          state: 'Daventry'
          zip: '07542'
      ]
    }

    # send delta
    if oplist
      receive 'delta', {
        root: 'users'
        timestamp: new Date
        oplist: oplist
      }

    # tell the client we're done
    finish()
