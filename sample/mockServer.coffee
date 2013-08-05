samplePayloads = require './data/samplePayloads'

module.exports = (deltas) ->

  (identity, receive, finish) ->

    # send manifest
    receive 'manifest', {
      timestamp: new Date
      myProfile: true,
      myStuff: true,
      visibleUsers: { name: true, _id: true }
    }

    # send payload
    for payload in samplePayloads
      receive 'payload', payload

    # send delta
    if deltas
      for delta in deltas
        receive 'delta', delta

    # tell the client we're done
    finish()
