net        = require("net")
JSONStream = require('JSONStream')
Bacon      = require("baconjs").Bacon
timers     = require("timers")

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

  calcDir = (angle) -> {
    dx: Math.sin(angle),
    dy: Math.cos(angle)
  }


  # Schedule sending noisy observations about position to client
  pos   = {  x: 0.0,   y: 0.0 }
  dir   = calcDir(Math.random() * 100.0)
  speed = Math.random() * 30
  time  = Date.now()


  sendNoisyPosition = ->
    # Change direction and speed
    if Math.random() < 0.0005
      dir   = calcDir(Math.random() * 100.0)
      speed = Math.random() * 30

      console.log "direction: (%s, %s)", dir.dx, dir.dy
      console.log "speed:     %s", speed

    # Update position and send noisy observation
    if Math.random() < 0.1
      now  = Date.now()
      diff = time - now
      time = now

      pos.x += dir.dx * diff * speed
      pos.y += dir.dy * diff * speed

      socket.write JSON.stringify {
        msg: "position",
        x: pos.x + (Math.random() - 0.5),
        y: pos.y + (Math.random() - 0.5)
      }

  timerId = timers.setInterval sendNoisyPosition, 1

  # This works!
  stream.onValue (json) ->
    console.log "Incoming JSON: %s", JSON.stringify(json)

    socket.write JSON.stringify(json)

  stream.onError (error) ->
    console.error "Error: %s", error

  stream.onEnd ->
    console.log "Stream end"
    timers.clearInterval timerId


server.listen port, "localhost"

console.log "listening at %d", port
