net        = require("net")
JSONStream = require('JSONStream')
Bacon      = require("baconjs").Bacon

port = 8080

server = net.createServer()

server.on "connection", (socket) ->
  console.log "Connection from %s", socket.remoteAddress

  stream = new Bacon.Bus()

  jsonStream = socket.pipe(JSONStream.parse())
  jsonStream.on 'data', (data) ->
    stream.push(data)

  jsonStream.on 'error', (error) ->
    stream.error(error)

  jsonStream.on 'close', ->
    stream.end()

  # This works!
  stream.onValue (json) ->
    console.log "Incoming JSON: %s", JSON.stringify(json)

    socket.write JSON.stringify(json)

  stream.onError (error) ->
    console.error "Error: %s", error

  stream.onEnd ->
    console.log "Stream end"

server.listen port, "localhost"

console.log "listening at %d", port
