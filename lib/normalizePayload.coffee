# This normalizes a payload (insert operation) into the same format used by updates.
# We don't send it over the wire optimized in order to minimize bandwidth costs.
module.exports = (event) ->
  oplist = []
  for record in event.data
    id = record.id
    delete record.id

    oplist.push
      operation: 'set'
      id: id
      path: '.'
      data: record

  normalized =
    root: event.root
    timestamp: event.timestamp
    oplist: oplist
