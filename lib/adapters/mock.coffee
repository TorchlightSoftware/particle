_ = require 'lodash'
{EventEmitter} = require 'events'
{Readable} = require 'stream'

# A data source that lets you set your own data and send deltas.
# Used for testing purposes.

class MockStream extends Readable
  constructor: ({@collName, payload}) ->
    super {objectMode: true}
    @send r for r in @formatPayload payload

  send: (event) ->
    @push event

  update: ({select, idSet}) ->

  _read: ->

  formatPayload: (records) ->
    events = for record in records
      namespace: "test.#{@collName}"
      timestamp: new Date
      _id: record._id
      operation: 'set'
      path: '.'
      data: record

    events[events.length-1].origin = 'end payload'
    return events

class MockAdapter extends EventEmitter
  constructor: (dataset) ->
    @dataset = dataset
    @streams = []

  # used to mock delta events
  send: (collName, event) ->
    targets = @streams.filter (s) -> s.collName is collName
    for target in targets
      target.mock.send event

  # complies with Mongo-Watch interface
  query: ({collName, idSet, select}, receiver) ->
    mock = new MockStream {collName, payload: @dataset[collName]}
    receiver null, mock
    meta = {mock, collName, idSet, select}
    @streams.push meta
    @emit 'addedQuery', meta

module.exports = MockAdapter
