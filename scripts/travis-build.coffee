#
#
# Slack reactions:
#   If build passed, thumbsup
#   If build failed, thumbsdown
#   If build errored, scream

# Description:
#   Listen to messages from Travis-CI bot and react
#
# Dependencies:
#   none
#
# Configuration:
#   none
#
# Commands:
#   Build .* failed - thumbsdown and tagged message
#   Build .* errored - scream and tagged message
#   Build .* passed - thumbsup
#
# Notes:
#   none
#
# Author:
#   seza443

module.exports = (robot) ->

  robot.hear /Build .* failed/i, (res) ->
    robot.adapter.client.web.reactions.add("thumbsdown", {channel: res.message.room, timestamp: res.message.id})
    res.send "@tanguy @alexandre Stop everything you're doing and fix this!"

  robot.hear /Build .* errored/i, (res) ->
    robot.adapter.client.web.reactions.add("scream", {channel: res.message.room, timestamp: res.message.id})
    res.send "@tanguy @alexandre You should check this error dudes"

  robot.hear /Build .* passed/i, (res) ->
    robot.adapter.client.web.reactions.add("thumbsup", {channel: res.message.room, timestamp: res.message.id})
