# hubot command count - Tells how many commands hubot knows
#

# Description:
#   Count number of commands
#
# Dependencies:
#   none
#
# Configuration:
#   none
#
# Commands:
#   hubot command count - Count the number of commands that hubot understand
#
# Notes:
#   none
#
# Author:
#   spajus - https://github.com/github/hubot-scripts/blob/master/src/scripts/reload.coffee

module.exports = (robot) ->

  robot.hear /command count/i, (msg) ->
    msg.send "I am aware of #{msg.robot.commands.length} commands"
