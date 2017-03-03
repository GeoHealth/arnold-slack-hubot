# Deployement actions:
#   If build of HAppi_backend passed, initiate deployement on FLYNN_DEV_APP_NAME
#   It needs FLYNN_DEV_APP_NAME, FLYNN_CLUSTER_KEY, FLYNN_USER, FLYNN_REMOTE_URL

# Description:
#   Deploy a commit to the Flynn test environment after a build succeed on Travis-CI
#
# Dependencies:
#   none
#
# Configuration:
#   FLYNN_DEV_APP_NAME = the name of the app on Flynn
#   FLYNN_CLUSTER_KEY  = the secret key of the cluster
#   FLYNN_USER         = the Flynn's user
#   FLYNN_REMOTE_URL   = the 'remote' where git can push the repo to Flynn
#
# Commands:
#   hubot deploy <sha_commit> to|on prod|production|test|dev|development|simulation - Deploy the commit sha_commit to the given environment of the Flynn cluster
#   Build #xx (sha_commit) of GeoHealth/HAppi_backend@master ... passed - Deploy the commit sha_commit to the test environment of the Flynn cluster
#
# Notes:
#   none
#
# Author:
#   seza443

deploy_to_flynn = (robot, res, repo_url, repo_name, commit_sha, flynn_user, flynn_key, flynn_remote_url, flynn_app_name) ->
  git_clone = "git clone --depth=50 --branch=master #{repo_url} #{repo_name}"
  cd_to_repo_folder = "cd #{repo_name}"
  git_checkout = "git checkout -qf #{commit_sha}"
  git_deactivate_certificate = "git config --global http.sslverify false"
  git_push = "git push --force https://#{flynn_user}:#{flynn_key}@#{flynn_remote_url}/#{flynn_app_name}.git #{commit_sha}:master"
  git_activate_certificate = "git config --global http.sslverify true"
  complete_command = git_clone + ';' + cd_to_repo_folder + ';' + git_checkout + ';' + git_deactivate_certificate + ';' + git_push + ';' + git_activate_certificate

  res.send complete_command

  @exec = require('child_process').exec
  @exec complete_command, (error, stdout, stderr) ->
    if error
      res.send error
      res.send stderr
    else
      res.send "#{repo_name} deployed to #{flynn_app_name} at #{commit_sha}"

module.exports = (robot) ->

  robot.hear /Build #\d+ \(.*\) \(https:\/\/.*\/.*\.\.\.(.*)\) of GeoHealth\/HAppi_backend@master.*passed.*/i, (res) ->
    commit_sha = res.match[1]
    flynn_app_name = process.env.FLYNN_DEV_APP_NAME
    repo_url = "https://github.com/GeoHealth/HAppi_backend.git"
    repo_name= "GeoHealth/HAppi_backend"
    flynn_user = process.env.FLYNN_USER
    flynn_key = process.env.FLYNN_CLUSTER_KEY
    flynn_remote_url = process.env.FLYNN_REMOTE_URL
    deploy_to_flynn(robot, res, repo_url, repo_name, commit_sha, flynn_user, flynn_key, flynn_remote_url, flynn_app_name)
