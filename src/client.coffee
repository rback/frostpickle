net        = require("net")
JSONStream = require('JSONStream')
Bacon      = require("baconjs").Bacon

stream = new Bacon.Bus()

client = net.connect 8080, "localhost", () ->
  console.log "Connected"
  client.write JSON.stringify({ "msg" : "join" })

client.on "error", (error) ->
  stream.error error

jsonStream = client.pipe(JSONStream.parse())

jsonStream.on "data", (data) ->
  stream.push data

jsonStream.on "error", (error) ->
  stream.error error

jsonStream.on "close", ->
  stream.end()

# This works!
stream.onValue (json) ->
  console.log "Incoming JSON: %s", JSON.stringify(json)

stream.onError (error) ->
  console.error "Error: %s", error

stream.onEnd ->
  console.log "Stream end"