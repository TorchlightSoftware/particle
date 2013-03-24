{inspect} = require 'util'
module.exports = (args...) ->
  console.log args.map((a) ->
    if (typeof a) is 'string' then a else inspect a, null, null)...
