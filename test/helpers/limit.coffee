_ = require 'lodash'

module.exports = (policy, sources) ->
  newPolicy = _.clone policy
  newPolicy.dataSources = _.pick newPolicy.dataSources, sources
  newPolicy
