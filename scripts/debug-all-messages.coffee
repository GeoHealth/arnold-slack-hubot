# Log all the received messages at DEBUG level
# To see the logged messages, use: 
# export HUBOT_LOG_LEVEL="debug"

module.exports = (robot) ->

  robot.hear /Test coverage has improved/i, (res) ->
    robot.logger.debug res.message
