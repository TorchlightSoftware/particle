#!/bin/bash
current=$(dirname $0)
lib=$current/lib
dist=$current/dist

rm -rf $dist
mkdir $dist

# CoffeeScript
coffee -cp $lib/collector.coffee > $dist/particle.js

echo "Build completed!"
