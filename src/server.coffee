restify = require("restify")
cluster = require("cluster")
util    = require("util")

if cluster.isMaster
  for i in [0...require('os').cpus().length]
    worker = cluster.fork()

  worker_ids = Object.keys(cluster.workers)

  tasks = []

  for id in worker_ids
    cluster.workers[id].on "message", (response) ->
      task = tasks[response.task_id]
      if task?
        console.log "winner: %s", response.text
        task.res.send response.text
        tasks.splice(tasks.indexOf(response.task_id), 1)
      else
        console.log "loser:  %s", response.text

  server = restify.createServer()

  current_worker = 0
  task_id        = 0

  next_worker = ->
    worker = cluster.workers[worker_ids[current_worker]]
    current_worker = (current_worker + 1) % worker_ids.length
    worker

  respond = (req, res, next) ->
    tasks[task_id] = {
      id:  task_id,
      res: res
    }

    # Send three tasks, winner will respond
    next_worker().send {
      task_id:   task_id,
      task_name: "task1"
    }
    next_worker().send {
      task_id:   task_id,
      task_name: "task2"
    }
    next_worker().send {
      task_id:   task_id,
      task_name: "task3"
    }

    task_id = task_id + 1

  server.get "/hello/:name", respond

  server.listen 8080, ->
    console.log "%s listening at %s", server.name, server.url
else
  process.on 'message', (request) =>
    switch request.task_name
      when "task1"
        process.send {
          task_id:  request.task_id,
          text:     util.format("task1 done at %s", cluster.worker.id)
        }
      when "task2"
        process.send {
          task_id:  request.task_id,
          text:     util.format("task2 done at %s", cluster.worker.id)
        }
      when "task3"
        process.send {
          task_id:  request.task_id,
          text:     util.format("task3 done at %s", cluster.worker.id)
        }