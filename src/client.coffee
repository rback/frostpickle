net        = require("net")
JSONStream = require('JSONStream')
Bacon      = require("baconjs").Bacon
numbers    = require("numbers")
restify    = require("restify")
ck         = require('coffeekup')
io         = require("socket.io")

stream = new Bacon.Bus()

stream.onError (error) ->
  console.error "Error: %s", error

stream.onEnd ->
  console.log "Stream end"

client = net.connect 8080, "localhost", () ->
  client.write JSON.stringify({ "msg" : "join" })

client.on "error", (error) ->
  stream.error error

jsonStream = client.pipe(JSONStream.parse())

jsonStream.on "data", (data) ->
  stream.push {
    timestamp: Date.now(),
    json:      data
  }

jsonStream.on "error", (error) ->
  stream.error error

jsonStream.on "close", ->
  stream.end()

positions = stream.filter((msg) -> msg.json.msg == "position").slidingWindow(10)

speed = positions.map (msgs) ->
  return 0.0 if msgs.length == 0

  first = msgs[0]
  last  = msgs[msgs.length - 1]

  timeDiff = last.timestamp - first.timestamp
  xDiff    = last.json.x - first.json.x
  yDiff    = last.json.y - first.json.y

  distance = Math.sqrt(xDiff*xDiff + yDiff*yDiff)
  distance / timeDiff

direction = positions.map (msgs) ->
  xs = msgs.map (i) -> i.json.x
  ys = msgs.map (i) -> i.json.y

  lr = numbers.statistic.linearRegression(xs, ys)

  dx   = 1.0
  dy   = lr(dx) - lr(0.0)
  dlen = Math.sqrt(dx*dx + dy*dy)

  dx = dx / dlen
  dy = dy / dlen

  # Wrap signs if we're going to negative direction, because
  # regression does not care about that.
  xDiff = xs[xs.length - 1] - xs[0]
  if xDiff > 0
    dx = -dx
    dy = -dy

  { dx: dx, dy: dy}

estimate = Bacon.combineTemplate({
  speed:     speed,
  direction: direction
})

server = restify.createServer
  formatters:
    'text/html': (req, res, body) ->
      return body.stack if body instanceof Error
      return body

server.use(restify.bodyParser({ mapParams: false }))

template = ck.compile ->
  doctype 5
  html ->
    head ->
      meta charset: 'utf-8'
      title '¡FrostPickle!'
      script src: "/socket.io/socket.io.js"
      script src: "/public/jquery-1.9.1.min.js"
      coffeescript ->
        socket = io.connect('http://localhost:8081')
        socket.on 'estimate', (data) ->
          $("#speed")    .text(data.speed.toPrecision(4))
          $("#direction").text("dx: #{data.direction.dx.toPrecision(3)}, dy: #{data.direction.dy.toPrecision(3)}")
  body ->
    div ->
      span "Speed: "
      span id: "speed", "?"
    div ->
      span "Direction: "
      span id: "direction", "?"

server.get "/", (req, res) ->
  res.send(template())
  next()

server.get /\/public\/.*/, restify.serveStatic({ directory: "." })

io = io.listen(server, { log: false})

io.sockets.on "connection", (s) ->
  console.log "connection"
  estimate.onValue (v) ->
    s.emit "estimate", v

server.listen 8081, ->
  console.log "%s listening at %s", server.name, server.url
