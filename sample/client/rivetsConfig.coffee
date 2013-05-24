define ['rivets.min'], (rivets) ->
  ->
    rivets.configure
      adapter:
        subscribe: (obj, keypath, callback) ->
          console.log 'subscribing:', keypath
          obj.on keypath, (data, event) ->
            console.log 'got event:', event
            callback event.data

        unsubscribe: (obj, keypath, callback) ->
          obj.off keypath, callback

        read: (obj, keypath) ->
          console.log 'reading:', keypath
          obj.get keypath

        #publish: (obj, keypath, value) ->
          #obj.set keypath, value
