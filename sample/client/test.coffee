require ['particle'], ({Collector}) ->

  renderData = (data) ->
    output = ''
    for k, v of data
      output += "<p><b>#{k}:</b> #{v}</p>\n"
    return output

  collector = new Collector
    #onDebug: (args...) -> console.log args...
    identity:
      sessionId: 'foo'

  collector.on 'data', (data, event) ->
    #console.log 'got data:', data
    $('#content').html renderData data.users[0]

  collector.register (err) ->
    if err
      console.log 'Error registering:', err
    else
      console.log 'Done registering.'
