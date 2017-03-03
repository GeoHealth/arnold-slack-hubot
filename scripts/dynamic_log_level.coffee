# Description:
#   Dynamically change the log level of hubot
#
# Dependencies:
#   log
#
# Configuration:
#   none
#
# Commands:
#   hubot log_level=<emergency|alert|critical|error|warning|notice|info|debug|default> - Change the log level to the given arg
#   hubot log_level? - Display the current log level
#
# Notes:
#   none
#
# Author:
#   seza443

Log = require 'log'
levels=['emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'info', 'debug']

module.exports = (robot) ->

  robot.respond /log_level=(.*)/i, (res) ->
    robot.logger = new Log res.match[1]

  robot.respond /log_level\?/i, (res) ->
    res.send "Current log level is #{levels[robot.logger.level]}"
