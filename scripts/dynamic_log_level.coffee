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

levels_to_string=['emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'info', 'debug']
string_to_level={'emergency':0, 'alert':1, 'critical':2, 'error':3, 'warning':4, 'notice':5, 'info':6, 'debug':7}

show_log_level = (robot, res) ->
  res.send "Current log level is #{levels_to_string[robot.logger.level]}"

module.exports = (robot) ->

  robot.respond /log_level=(.*)/i, (res) ->
    robot.logger.level = string_to_level[res.match[1]]
    show_log_level(robot, res)

  robot.respond /log_level\?/i, (res) ->
    show_log_level(robot, res)
