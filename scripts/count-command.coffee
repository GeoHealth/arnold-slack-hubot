# hubot command count - Tells how many commands hubot knows
# source: https://github.com/github/hubot-scripts/blob/master/src/scripts/reload.coffee

module.exports = (robot) ->

  robot.hear /command count/i, (msg) ->
    msg.send "I am aware of #{msg.robot.commands.length} commands"
