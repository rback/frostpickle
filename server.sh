#!/bin/bash
set -e
./node_modules/coffee-script/bin/coffee -c src/server.coffee
node src/server.js
