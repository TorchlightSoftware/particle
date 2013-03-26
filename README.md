# Particle

This is a library for distributed state synchronization.  Clients can register with a server, and their local data models will be kept up to date as the data on the server changes.  To begin with we are focused on Mongo as the data source, but in the future Redis and other data sources should be supported.

Currently the client side data model is read only.  This is not enforced, but if you change it your data will now be out of sync with the server.  Instead you should use an out of band method such as RPC or REST to initiate changes on the server, and let them trickle back down.

In the future, it is possible we will support a more direct strategy for updating the data model.  This is a complex problem to solve because you need to handle conflict resolution on shared data.  Ultimately the server must have final say in what operations are allowed.

## Install

```bash
npm install particle

component install TorchlightSoftware/particle
```

## Collector (Client)

```coffee-script
particle = require 'particle'
collector = new particle.Collector

  identity:
    sessionId: 'foo'

  # I should recieve a delta event
  onData: (data, event) =>
    console.log {data, event}
```

## Stream (Server)

```coffee-script
particle = require 'particle'
MongoWatch = require 'mongo-watch'
watcher = new MongoWatch {format: 'normal'}
users = # a collection from mongo driver or mongoose

stream = new particle.Stream
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

## Configuring Your Particle Stream

When you create a Stream, which is the server component to Particle, you pass it a configuration.  The Stream and its configuration reside server side for security purposes, so you never send out any data that you don't want the user to have access to.

The fields below are required unless you see a * after the name.

### Data Sources

Each data source corresponds to a root property on the client side data model (collector.data).  The data source configuration controls where data will come from and how it will be filtered.

* Manifest

The manifest is a data structure which controls what fields get pushed out to a Collector.  It treats arrays and objects the same, and does not care about data types.  It will be applied to any data returned by the Payload or Delta functions.  It is comprised of nested objects and boolean values.  Data is not represented by default, so only the value 'true' has any meaning.  You can use 'false' for explicit documentation if you would like.

You can assign 'true' at any point in the data structure.  For instance, if you put 'true' at the root then no data will be filtered.

* Payload

This function is responsible for retrieving initial data when a new Collector registers.  It is passed the Identity associated with this Collector, and a callback function (err, data) for returning the data.  You can use the Identity to limit the fields returned.  The data returned by a Mongo query is suitable for this.  Essentially it needs to be a collection of documents, where each document is comprised of a root object and nested objects, arrays, and data values.

* Delta

This function is passed the Identity of the Collector, and a receiver function.  It is responsible for wiring up some kind of event source which will be forwarded by the Stream to any registered Collectors.

I wrote a library for listening to the mongo oplog which can be used for this purpose.  You can find it [here](https://github.com/torchlightsoftware/mongo-watch).  You want to use the 'normal' format to get a message format compatible with Particle.  Note that this will not work for shared DB hosting solutions.  If you are interested in getting something working for that sort of platform I have some ideas... please contact me.

### Identity Lookup*

This is the first step taken whenever a new Collector registers.  You will be passed the identity that the Collector is claiming, and you have the opportunity to look up additional data and associate it with this Collector, or you can return an error in which case the registration will fail and the Collector will be notified.  Any additional data that you look up will be stored server side and will not be passed back to the Collector.  However, it will be passed to the Payload and Delta functions, so you can use it in filtering the data that a Collector receives.

### onDebug*

The 'onDebug' value can be set to a logging function, for instance console.log.  Whenever Stream receives data from a data source, or sends data to a Collector, your function will be notified.  Other important events are sent as well.

This is really useful if you are trying to troubleshoot a configuration to find out why data is not being transmitted.

### disconnect*

Each Particle Stream instance exposes a disconnect method which can be used to shut it down.  In addition to its internal behavior, you can specify your own behavior, such as shutting down any watchers you established.

## Designing Your Data Model

By combining field limiting from the manifest, and the record limiting ability of the payload and delta functions, you can achieve precise control over what data a Collector has access to.

For instance, if a particular Data Source represents the 'current user', you can pull their userID from the Identity argument and query for only the record that matches.  Another Data Source might be coming from the same database collection, but retrieve ALL the users' records with a more restrictive Manifest.

## Collector Configuration

The collector's configuration is pretty minimal.  It doesn't need to know about what data it will be managing, it just needs your credentials and the location of the Stream it's connecting to.  Here are the fields you can use:

### Identity

A hash object containing any data you wish to use for authentication and access control.  This could be a sessionId which you got from logging in via some out-of-band channel.  For instance, RPC or basic auth.  Particle does not handle authentication - this allows you to integrate it with your existing strategy.

### Register*

This is a low level function which should not normally be used.  See the debugging section below for details.  In its absence the Collector will try to connect to its Stream using websockets (which is usually what you want).

## The Particle Lifecycle

When a Stream is created, it stores the configuration and waits for Collectors to register.  For each Collector that registers it does the following:

1. Verifies the Collector's identity
2. Sends a manifest
3. Sends payloads for all data sources
4. Wires up listeners for deltas

When a Collector is created, it immediately tries to register with a Stream based on its configuration.  It sends the Stream its identity and waits for a success/failure.  The operation succeeds if the Identity lookup is successful (or none is defined), and then the Collector waits for its initial data.

The Collector starts out with a 'status' property set to 'waiting'.  It expects to receive:

1. A manifest
2. A payload for each data source listed in the manifest

Once it has received the manifest and data for all sources, its status will change to 'ready'.  In addition the collector has a function called 'ready' which takes a callback and will either call it immediately if the status is 'ready', or will call it once the status changes to 'ready'.  As of this writing, there are no other statuses defined.

The onData property of the Collector configuration is used to listen to changes.  Why is it provided up front and not dynamically addible like an EventEmitter?  Well, right now the Collector is performing a registration as soon as it is initialized, and you don't want to miss any events, so you need to provide your listener up front.  This is a very early draft of the system, and I will probably be changing to a manual 'register' call so that you can wire up your listeners in a nicer way.

The function you provide to onData will receive (data, event).  Data is the entire data root, and event is a description of the change which occurred.  The event format follows the specification for a Delta (see Message Format in next section).  All events will look like Deltas, even inserts and the data retrieved by the payloads.

## The Particle Message Format

Three types of messages are passed between the Particle Stream and Collector:

* Manifest
* Payload
* Delta

These all have formats which I feel are general enough to apply to many different data sources.  They were modeled around MongoDB however, so some adjustment may need to be made for supporting other types of DBs.  I am working on formalizing these message formats using JSON Schema, and will make available the documentation as well as the schemas for use in other third party libraries that interact with Particle.

For now, please refer to the tests and also keep an eye on [this document](https://github.com/TorchlightSoftware/particle/blob/master/lib/messageFormats.coffee).  Let me know if you have questions.


## Debugging

I tried to make the interface a balance of clean and robust.  If you run into trouble and want to find out what's going on inside, the following features will be helpful.

### onDebug

This is supported on both Collector and Stream instances.  When you pass a logging function such as console.log, you will be notified of relevant events in the Particle lifecycle.  Turning this on for most production and even development environments is not recommended, as the data volume will be huge.

### Register

This function is present as a configuration option on the Collector, and as a fully implemented function on the Stream.

We'll talk about the Collector first.  You could add a custom function here for the purpose of:

* debugging the Collector
* connecting to a custom event source
* mocking out the data model

The last case is particularly useful - if you mock out the client side data model you can allow front end developers to continue work unimpeded by the back end implementation.

The Stream's implementation of this function accepts the following arguments:

* identity
* a receiver method (messageName, event) - call this whenever you want to send the Collector data
* a callback (err) - to be called when registration has completed (or failed)

It is responsible for establishing a communication channel with a particular Collector.  See Particle Message Format above.  You can call this function manually in order to mimic a Collector registration.

## Credit/Inspiration

This was mainly inspired by personal experience of trying to build a chat server based on message passing semantics.  We came to the conclusion that the tool we were using did not allow us to describe the problem at the right level of abstraction.  We don't really care how the data gets there, and we don't want to miss any data, which is a danger with message passing.  We need to always have the current state of the data, and we need to be notified of changes.

As the library was under construction, I came across this article:

http://martinfowler.com/bliki/CQRS.html

I think this is a good starting point for understanding how different data-acquisition strategies can work together in an event driven architecture.  Ultimately I see technologies like Particle enabling us to build real time awareness systems which can give modern businesses a huge competitive advantage.  These technologies can also be used to build systems that feel responsive and natural, and take a more active role in serving our needs.

Another good resource on the subject is the book [Event Processing: Designing IT Systems for Agile Companies](http://www.amazon.com/Event-Processing-Designing-Systems-Companies/dp/0071633502).

Here's an [interview with the author](http://www.youtube.com/watch?v=b6Lb0FRojXM).

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
