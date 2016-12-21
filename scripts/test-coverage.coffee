# Listen to messages of Codeclimate bot and tag Tanguy and Alexandre if code coverage goes down

module.exports = (robot) ->

  robot.hear /Test coverage .* has declined/i, (res) ->
    robot.adapter.client.web.reactions.add("thumbsdown", {channel: res.message.room, timestamp: res.message.id})
    res.send "@tanguy @alexandre Hey better write some tests!"
  
  robot.hear /Test coverage .* has improved/i, (res) ->
    #robot.logger.debug res.message
    robot.adapter.client.web.reactions.add("thumbsup", {channel: res.message.room, timestamp: res.message.id})
