should = require 'should'
{getType} = require 'ale'
logger = require 'torch'
http = require 'http'
_ = require 'lodash'

# get rid of annoying warnings
require('../lib/patchEventEmitter')()

{Collector, Stream} = require '../.'
samplePolicy = require('../sample/data/samplePolicy')()
mongoWatchPolicy = require('../sample/data/mongoWatchPolicy')()
limit = require './helpers/limit'

mockSourceData = require '../sample/data/mockSourceData'
loadTestData = require '../sample/loadTestData'
removeTestData = require '../sample/removeTestData'

randomPort = (-> Math.floor(Math.random() * 1000) + 8000)()

expectedCache =
  'userstuffs._id':
     '6': { 'users._id': 4, 'stuffs._id': 1 }
     '7': { 'users._id': 4, 'stuffs._id': 2 }
     '8': { 'users._id': 5, 'stuffs._id': 2 }
  'users._id':
     '4': { 'users.accountId': 1, 'userstuffs._id': [ 6, 7 ] }
     '5': { 'users.accountId': 1, 'userstuffs._id': [ 8 ] }
  'stuffs._id':
     '1': { 'userstuffs._id': [ 6 ] }
     '2': { 'userstuffs._id': [ 7, 8 ] }
  'users.accountId':
     '1': { 'users._id': [ 4, 5 ] }

expectedData = {
  myProfile: [
    { _id: 4, accountId: 1, name: 'Bob', email: 'bob@foo.com' }
  ]
  myStuff: [
    { _id: 1, stuff: [ 'foo', 'bar' ] }
    { _id: 2, stuff: [ 'baz' ] }
  ]
  visibleUsers: [
    { _id: 4, accountId: 1, name: 'Bob', email: 'bob@foo.com' }
    { _id: 5, accountId: 1, name: 'Jane', email: 'jane@foo.com' }
  ]
}

filteredData = _.clone expectedData
filteredData.visibleUsers = [
  { _id: 4, name: 'Bob'}
  { _id: 5, name: 'Jane'}
]

{MongoClient, ObjectID} = require 'mongodb'

describe 'Integration', ->
  beforeEach (done) ->
    removeTestData mockSourceData, done

  after (done) ->
    removeTestData mockSourceData, done

  it 'should work via network', (done) ->

    # create stream/server
    policy = limit samplePolicy, ['myProfile', 'myStuff', 'visibleUsers']
    #policy.onDebug = logger.grey
    stream = new Stream policy

    server = http.createServer()
    server.listen randomPort, (err) =>
      should.not.exist err

      stream.init(server)

      ## create collector/client
      collector = new Collector {
        #onDebug: logger.white
        network:
          port: randomPort
        identity:
          userId: 4
          accountId: 1
      }

      collector.register()
      collector.ready =>
        collector.data.should.eql expectedData
        done()

  it 'no data should work with mongo-watch', (done) ->

    # create stream/server
    policy = limit mongoWatchPolicy, ['myProfile', 'myStuff', 'visibleUsers']
    #policy.onDebug = logger.grey
    stream = new Stream policy

    # create collector/client
    collector = new Collector {
      #onDebug: logger.white
      onRegister: stream.register.bind(stream)
      identity:
        userId: 1
        accountId: 1
    }

    collector.register()
    collector.ready =>
      collector.data.should.eql {
        visibleUsers: []
        myProfile: []
        myStuff: []
      }
      done()

  it 'with data should work with mongo-watch', (done) ->
    loadTestData mockSourceData, (err, data) ->
      should.not.exist err

      [stuffs, users] = data
      bob = _.find users, (u) -> u.name is 'Bob'

      # create stream/server
      policy = limit mongoWatchPolicy, ['myProfile', 'myStuff', 'visibleUsers']
      #policy.onDebug = logger.grey
      stream = new Stream policy

      stream.ready =>
        stream.cache._cache.should.eql expectedCache

        # create collector/client
        collector = new Collector {
          #onDebug: logger.white
          onRegister: stream.register.bind(stream)
          identity:
            userId: bob._id
            accountId: bob.accountId
        }

        collector.register()
        collector.ready =>
          collector.data.should.eql filteredData
          done()
