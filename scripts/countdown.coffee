# Description:
#   Countdown timer. Starts at the specified number and counts down to 0.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot deadline - Show the number of days
#
module.exports = (robot) ->
    robot.respond /deadline/i, (msg) ->
        today = new Date
        msg.send today.toTimeString()
