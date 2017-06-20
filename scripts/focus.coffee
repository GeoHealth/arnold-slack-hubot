# Description:
#   Tell team to focus on presentation
#
# Commands:
#   what's up?
#
module.exports = (robot) ->

  robot.hear /what's up?/i, (res) ->
    res.send 'Hey, you should focus on you presentation :wink:'
