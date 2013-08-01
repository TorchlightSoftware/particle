should = require 'should'
_ = require 'lodash'
{getType} = require 'ale'
logger = require 'torch'
{focus} = require 'qi'

{contains} = require '../lib/util'
{Collector} = require '../'
mockServer = require '../sample/mockServer'

describe 'Collector', ->

  it 'should initialize with data', (done) ->
    step = focus done
    receivedEvent = step()
    onReady = step()

    # When I register a new client
    @collector = new Collector
      onRegister: mockServer()
      #onDebug: logger.grey

    @collector.once 'data', (data, event) ->
      should.exist event, 'expected event'
      receivedEvent()

    @collector.register()

    # And it should send
    @collector.ready =>
      should.exist @collector.data.visibleUsers?.length
      @collector.data.visibleUsers.length.should.eql 2
      onReady()

  it 'should receive an update delta', (done) ->

    @collector = new Collector
      # When I register a new client
      onRegister: mockServer [
          origin: 'delta'
          root: 'myProfile'
          namespace: 'test.users'
          timestamp: new Date
          operation: 'set'
          _id: 1
          path: 'address.state'
          data: 'Lake Maylie'
        ]

    # I should recieve a delta event
    deltaTest = (data, event) =>
      should.exist data
      should.exist event

      if event.origin is 'delta'
        should.exist event.root, 'expected root'

        event.root.should.eql 'myProfile'

        expected =
          origin: 'delta'
          root: 'myProfile'
          namespace: 'test.users'
          operation: 'set'
          _id: 1
          path: 'address.state'
          data: 'Lake Maylie'

        if contains event, expected
          @collector.removeListener 'delta', deltaTest
          done()

    @collector.on 'data', deltaTest
    @collector.register()

  it 'should filter events', (done) ->

    @collector = new Collector
      # When I register a new client
      onRegister: mockServer [
          origin: 'delta'
          root: 'myProfile'
          namespace: 'test.users'
          timestamp: new Date
          operation: 'set'
          _id: 1
          path: 'address.state'
          data: 'Lake Maylie'
        ]

    # I should recieve a delta event
    deltaTest = (data, event) =>
      should.exist data
      should.exist event

      if event.origin is 'delta'
        should.exist event.root, 'expected root'

        event.root.should.eql 'myProfile'

        expected =
          origin: 'delta'
          root: 'myProfile'
          namespace: 'test.users'
          operation: 'set'
          _id: 1
          path: 'address.state'
          data: 'Lake Maylie'

        if contains event, expected
          @collector.removeListener 'delta', deltaTest
          done()

    @collector.once 'myProfile.address.state', deltaTest
    @collector.register()

  it 'should use wildcard', (done) ->

    @collector = new Collector
      # When I register a new client
      onRegister: mockServer [
          origin: 'delta'
          root: 'myProfile'
          namespace: 'test.users'
          timestamp: new Date
          operation: 'set'
          _id: 1
          path: 'address.state'
          data: 'Lake Maylie'
        ]

    # I should recieve a delta event
    deltaTest = (data, event) =>
      should.exist data
      should.exist event

      if event.origin is 'delta'
        should.exist event.root, 'expected root'

        event.root.should.eql 'myProfile'

        expected =
          origin: 'delta'
          root: 'myProfile'
          namespace: 'test.users'
          operation: 'set'
          _id: 1
          path: 'address.state'
          data: 'Lake Maylie'

        if contains event, expected
          @collector.removeListener 'delta', deltaTest
          done()

    @collector.once 'myProfile.address.*', deltaTest
    @collector.register()
