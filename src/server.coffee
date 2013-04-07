restify = require("restify")
Bacon   = require("baconjs").Bacon

server = restify.createServer()

server.use restify.bodyParser()

stream = new Bacon.Bus()

stream.onValue (msg) ->
  console.log "Incoming JSON, %s", JSON.stringify(msg.json)
  msg.response.header("Content-Type: application/json")
  msg.response.send msg.json

stream.onError (error) ->
  console.error "Error: %s", error

stream.onEnd ->
  console.log "Stream end"

respondJson = (req, res, next) ->
  stream.push({
    json:     JSON.parse(req.body),
    response: res
  })

server.post "/json", respondJson
 
server.listen 8080, ->
    console.log "%s listening at %s", server.name, server.url