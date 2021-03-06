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
        deadlineDate = new Date(Date.UTC(2017,5,9,21,59))
        result = deadlineDate - today
        x = result / 1000
        seconds = x % 60
        x /= 60
        minutes = x % 60
        x /= 60
        hours = x % 24
        x /= 24
        days = x
        msg.send "Il reste " + parseInt(days) + " jours " + parseInt(hours) + " heures " + parseInt(minutes) + " minutes " + parseInt(seconds) + " secondes"
