module.exports =
  Collector: require './collector'

unless window?
  module.exports.Stream = require './stream'
