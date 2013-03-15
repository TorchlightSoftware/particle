define ['vendor/particle', 'vendor/pulsar', 'vendor/vein'], (particle, Pulsar, Vein) ->
  $ ->

    data =
      sessionId: 'foo'

    pulse = Pulsar.createClient {port: 4001}

    rpc = Vein.createClient {}
    rpc.ready ->

      options =
        register: rpc['particle/register']
        activateDelta: (listener) ->
          channel = pulse.channel "particle:session:#{data.sessionId}"
          channel.on 'delta', listener

      collector = new particle.Collector options

      collector.ready ->
        window.dataRoot = collector.data
        $('.displayUser').html collector.data.you.id
