{inspect} = require 'util'
should = require 'should'
{Collector} = require '../'
mockServer = require '../sample/mockServer'
_ = require 'lodash'
{getType} = require '../lib/util'

describe 'Collector', ->

  it 'should initialize with data', (done) ->

    # When I register a new client
    @collector = new Collector
      identity:
        sessionId: 'foo'
      register: mockServer()
      onData: (data, event) ->
        should.exist event, 'expected event'
        (getType event.oplist).should.eql 'Array'
        event.oplist.should.have.length 1

    # And it should send
    @collector.ready =>
      should.exist @collector.data.users?.length
      @collector.data.users.length.should.eql 1
      done()

  it 'should receive an update delta', (done) ->

    @collector = new Collector

      identity:
        sessionId: 'foo'

      # When I register a new client
      register: mockServer [
          operation: 'set'
          id: 5
          path: 'address.state'
          data: 'Lake Maylie'
        ]

      # I should recieve a delta event
      onData: (data, event) =>
        should.exist data
        should.exist event
        should.exist event.root, 'expected root'

        event.root.should.eql 'users'

        expected =
          operation: 'set'
          id: 5
          path: 'address.state'
          data: 'Lake Maylie'

        for op in event.oplist
          done() if _.isEqual op, expected
