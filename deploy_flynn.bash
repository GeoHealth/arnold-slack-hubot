#!/bin/bash

repo_url=$1
repo_name=$2
commit_sha=$3
flynn_user=$4
flynn_key=$5
flynn_remote_url=$6
flynn_app_name=$7

# echo "repo_url = $1"
# echo "repo_name = $2"
# echo "commit_sha = $3"
# echo "flynn_user = $4"
# echo "flynn_key = $5"
# echo "flynn_remote_url = $6"
# echo "flynn_app_name = $7"

cd ~
git clone --depth=50 --branch=master $repo_url $repo_name
echo 'clone ok'
cd $repo_name
echo 'cd ok'
git checkout -qf $commit_sha
echo 'checkout ok'
git config --global http.sslverify false
echo 'ssl false ok'
git push --force https://$flynn_user:$flynn_key@$flynn_remote_url/$flynn_app_name.git $commit_sha:master
echo 'deploy ok'
git config --global http.sslverify true
echo 'ssl true ok'
cd ~
rm -rf $repo_name
echo 'repo folder removed'
