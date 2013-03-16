# Particle

This is a library for distributed state synchronization.  Clients can register with a server, and their local data models will be kept up to data as the data on the server changes.  To begin with we are focused on listening to changes in Mongo, but in the future Redis and other data sources should be supported.

## Client

```coffee-script
particle = require 'particle'
client = new particle.Client

  identity:
    sessionId: 'foo'

  # I should recieve a delta event
  onData: (data, event) =>
```

## Server

```coffee-script
particle = require 'particle'
MongoWatch = require 'mongo-watch'
watcher = new MongoWatch {format: 'normal'}
users = # a collection from mongo driver or mongoose

server = new particle.Server
  #onDebug: console.log

  identityLookup: (identity, done) ->
    done null, {accountId: 1}

  dataSources:

    users:
      manifest: # limit what fields should be allowed
        email: true
        todo: {list: true}

      payload: # get initial data for users
        (identity, done) ->
          users.find().toArray (err, data) ->
            done err, {data: data, timestamp: new Date}

      delta: # wire up deltas for users
        (identity, listener) ->
          watcher.watch "test.users", listener

  disconnect: ->
    watcher.stopAll()
```

## Install

```bash
npm install particle
```

## LICENSE

(MIT License)

Copyright (c) 2013 Torchlight Software <info@torchlightsoftware.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
