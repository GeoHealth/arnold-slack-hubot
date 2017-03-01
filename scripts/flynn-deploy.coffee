# Deployement actions:
#   If build of HAppi_backend passed, initiate deployement on FLYNN_DEV_APP_NAME
#   It needs the FLYNN_CLUSTER_KEY

trying_to_run_command = (robot, res) ->
  @exec = require('child_process').exec
  @exec 'pwd', (error, stdout, stderr) ->
    if error
        res.send error
        res.send stderr
    else
        res.send stdout

module.exports = (robot) ->

  robot.hear /Build #\d+ \((.*)\) of GeoHealth\/HAppi_backend./i, (res) ->
    commit_sha = res.match[1]
    app_name = process.env.FLYNN_DEV_APP_NAME
    res.send "Deploying #{commit_sha} on #{app_name}"
