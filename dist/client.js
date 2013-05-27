// Generated by CoffeeScript 1.6.2
(function() {
  var Client, client, createClientWrapper, queued;

  createClientWrapper = require('protosock').createClientWrapper;

  queued = [];

  client = {
    start: function() {
      return this.status = 'waiting';
    },
    connect: function(socket) {
      var q, _i, _len;

      this.status = 'ready';
      for (_i = 0, _len = queued.length; _i < _len; _i++) {
        q = queued[_i];
        q();
      }
      return queued = [];
    },
    options: {
      namespace: 'particle',
      resource: 'default',
      debug: false
    },
    message: function(socket, msg) {
      switch (msg.type) {
        case 'registered':
          return this.onRegistered(msg.err);
        case 'data':
          return this.receive(msg.name, msg.event);
      }
    },
    error: function(socket, err) {
      return console.log('client err:', {
        err: err
      });
    },
    ready: function(done) {
      if (this.status === 'ready') {
        return done();
      } else {
        return queued.push(done);
      }
    },
    register: function(identity, receive, finish) {
      var _this = this;

      return this.ready(function() {
        _this.ssocket.write({
          type: 'register',
          identity: identity
        });
        _this.onRegistered = finish;
        return _this.receive = receive;
      });
    }
  };

  module.exports = Client = createClientWrapper(client);

}).call(this);