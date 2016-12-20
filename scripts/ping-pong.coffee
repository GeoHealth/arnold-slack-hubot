module.exports = (robot) ->

  
  robot.hear /pong/i, (res) ->
    res.send "ping"

