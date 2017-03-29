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
#   hubot countdown <x> - Count down from [x] to 0, at one second intervals
#
module.exports = (robot) ->
    robot.respond /thesisDeadline /i, (msg) ->
        days = 76
        tick = () ->
            msg.send "#{count--}"
            if count > 0
                setTimeout(tick, 86400)
            else
                setTimeout(go, 86400)
        go = () ->
            msg.send days + "avant la deadline du mémoire"
            days = days - 1
        if count <= 0
            return
        tick()
