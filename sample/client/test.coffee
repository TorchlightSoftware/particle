require ['particle', 'rivets.min', 'rivetsConfig'], ({Collector}, rivets, rivetsConfig) ->

  renderData = (data) ->
    output = ''
    for k, v of data
      output += "<p><b>#{k}:</b> #{v}</p>\n"
    return output

  collector = new Collector
    #onDebug: (args...) -> console.log args...
    identity:
      sessionId: 'foo'

  # bind manual UI updates
  collector.on 'data', (data, event) ->
    #console.log 'got data:', data
    $('#content').html renderData data.users[0]

  # bind rivets UI updates
  rivetsConfig()
  collector.ready ->
    data = collector.data
    console.log 'binding with data:', data
    rivets.bind $('#rivets'), data

  collector.register (err) ->
    if err
      console.log 'Error registering:', err
    else
      console.log 'Done registering.'
