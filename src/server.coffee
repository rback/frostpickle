restify = require("restify")
Bacon = require('baconjs').Bacon
ck = require('coffeekup')
util = require('util')

server = restify.createServer
  formatters:
    'text/html': (req, res, body) ->
      return body.stack if body instanceof Error
      return body

server.use(restify.bodyParser({ mapParams: false }));

redirect_to_job = (req, res, next) ->
  console.log 'Received result: ' + req.body.result
  res.setHeader('Location', '/job')
  res.send(302)
  next()

template = ck.compile ->
  doctype 5
  html ->
    head ->
      meta charset: 'utf-8'
      title 'Mobile Djuiz'
      coffeescript ->
        window.onload = window.setTimeout (->
            form = document.forms["resultForm"]
            form.result.value = '42'
            form.submit()
          ), 2000
  body ->
    form method: 'post', action: 'result', id: 'resultForm', ->
      input type: 'text', name: 'result'

server.get "/job", (req, res) ->
  res.send(template())
  next()

server.post "/result", redirect_to_job

server.listen 8080, ->
  console.log "%s listening at %s", server.name, server.url