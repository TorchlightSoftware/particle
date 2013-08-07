require ['particle'], ({Collector}) ->

  renderData = (data) ->
    output = ''
    for k, v of data
      output += "<p><b>#{k}:</b> #{v}</p>\n"
    return output

  collector = new Collector
    onDebug: (args...) -> console.log args...
    identity:
      userId: 4

  collector.on 'myProfile.**', (data, event) ->
    #console.log 'got data:', data
    $('#content').html renderData data.myProfile[0]

  collector.register (err) ->
    if err
      console.log 'Error registering:', err
    else
      console.log 'Done registering.'
