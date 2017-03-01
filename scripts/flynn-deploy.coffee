# Deployement actions:
#   If build of HAppi_backend passed, initiate deployement on FLYNN_DEV_APP_NAME
#   It needs FLYNN_DEV_APP_NAME, FLYNN_CLUSTER_KEY, FLYNN_USER, FLYNN_REMOTE_URL

deploy_to_flynn = (robot, res, repo_url, repo_name, commit_sha, flynn_user, flynn_key, flynn_remote_url, flynn_app_name) ->
  git_clone = "git clone --depth=50 --branch=master #{repo_url} #{repo_name}"
  cd_to_repo_folder = "cd #{repo_name}"
  git_checkout = "git checkout -qf #{commit_sha}"
  git_push = "git push --force https://#{flynn_user}:#{flynn_key}@#{flynn_remote_url}/#{flynn_app_name}.git #{commit_sha}:master"
  @exec = require('child_process').exec

  res.send git_clone
  @exec git_clone, (error, stdout, stderr) ->
    if error
        res.send error
        res.send stderr
    else
        res.send cd_to_repo_folder
        @exec cd_to_repo_folder, (error, stdout, stderr) ->
          if error
              res.send error
              res.send stderr
          else
              res.send git_checkout
              @exec git_checkout, (error, stdout, stderr) ->
                if error
                    res.send error
                    res.send stderr
                else
                    res.send git_push
                    @exec git_push, (error, stdout, stderr) ->
                      if error
                          res.send error
                          res.send stderr
                      else
                          res.send stdout

module.exports = (robot) ->

  robot.hear /Build #\d+ \((.*)\) of GeoHealth\/HAppi_backend./i, (res) ->
    commit_sha = res.match[1]
    flynn_app_name = process.env.FLYNN_DEV_APP_NAME
    repo_url = "https://github.com/GeoHealth/HAppi_backend.git"
    repo_name= "GeoHealth/HAppi_backend"
    flynn_user = process.env.FLYNN_USER
    flynn_key = process.env.FLYNN_CLUSTER_KEY
    flynn_remote_url = process.env.FLYNN_REMOTE_URL
    res.send "Deploying #{commit_sha} on #{flynn_app_name}"
    deploy_to_flynn(robot, res, repo_url, repo_name, commit_sha, flynn_user, flynn_key, flynn_remote_url, flynn_app_name)
