# Description:
#   Log all the received messages at DEBUG level
#
# Dependencies:
#   none
#
# Configuration:
#   HUBOT_LOG_LEVEL="debug"
#
# Commands:
#   none
#
# Notes:
#   none
#
# Author:
#   seza443

module.exports = (robot) ->

  robot.hear /.*/i, (res) ->
    robot.logger.debug res.message
