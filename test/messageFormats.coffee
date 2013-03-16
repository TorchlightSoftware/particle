should = require 'should'
{streamInPolicy} = require '../lib/messageFormats'
mongoWatchPolicy = require '../sample/mongoWatchPolicy'

JaySchema = require 'jayschema'
jsv = new JaySchema

describe 'Stream - Policy Input', ->

  it 'should validate mongoWatchPolicy', ->
    errors = streamInPolicy mongoWatchPolicy()
    errors.should.be.empty

describe 'JSV', ->

  it 'should validate a function', ->
    errors = jsv.validate {fn: ->}, {
      properties:
        fn:
          type: 'function'
    }
    errors.should.be.empty
