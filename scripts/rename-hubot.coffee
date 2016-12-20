# Description:
#   Tell people hubot's new name if they use the old one
#
# Commands:
#   None
#
module.exports = (robot) ->

  robot.hear /hubot/i, (res) ->
    robot.logger.debug "Received message #{res.message.text}"
    response = "Sorry, I'm a diva and only respond to #{robot.name}"
    response += " or #{robot.alias}" if robot.alias
    res.send response
