restify = require("restify")
server = restify.createServer()
 
respond = (req, res, next) ->
    res.send "Hello #{req.params.name}"
   
server.get "/hello/:name", respond
 
server.listen 8080, ->
    console.log "%s listening at %s", server.name, server.url