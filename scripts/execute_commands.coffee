# Description
#   A hubot script to execute commands
#
# Configuration:
#
# Commands:
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   lukasz@sredni.pl

module.exports = (robot) ->

  robot.respond /execute (.*)?$/i, (msg) ->
    command = msg.match[1]

    @exec = require('child_process').exec
    command = "cd ~; #{command}"

    msg.reply "Lock and load, executing..."

    @exec command, (error, stdout, stderr) ->
      msg.send stdout
      if stderr
        msg.send "ERROR (stderr): " + stderr
      if error
        msg.send "ERROR (error)" + error
