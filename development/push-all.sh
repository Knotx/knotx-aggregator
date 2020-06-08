#!/usr/bin/env bash

# Use this script to create PRs for cross-repository changes.
# Iterates through repositories, commits and pushes all changes (to the branch, also sets upstream) and uses https://hub.github.com/ to create pull requests.

#########################
# The command line help #
#########################
help() {
    echo "Usage: $0 [option...] " >&2
    echo
    echo "   -r                         root folder path for all Knot.x repositories"
    echo "   -b                         GIT branch name"
    echo "   -m                         commit message for all changes that will be pushed"
    echo "   sh push-all.sh -r projects/knotx -m 'Cross-repo change #123' -b feature/my-cross-repo-change            commits, pushes and creates pull requests for all repositories that hava changes"
    exit 1
}

#########################
#          Main         #
#########################

while getopts hr:m:b: option
do
  case "${option}"
    in
    h) help;;
    r) ROOT=${OPTARG};;
    m) MESSAGE=${OPTARG};;
    b) BRANCH=${OPTARG};;
  esac
done

echo "Script root catalogue [$ROOT]"
echo "Commit message [$MESSAGE]"
echo "Git branch [$BRANCH]"

repos=()
IFS=$'\n' read -d '' -r -a repos < ../repositories.cfg

for project in "${repos[@]}"
do
  projectDir="${ROOT}/${project}"
  echo "Processing $project in $projectDir"

  git --git-dir=${projectDir}/.git --work-tree=${projectDir} add .
  git --git-dir=${projectDir}/.git --work-tree=${projectDir} commit -m "${MESSAGE}"
  git --git-dir=${projectDir}/.git --work-tree=${projectDir} push -u origin ${BRANCH}
  hub --git-dir=${projectDir}/.git --work-tree=${projectDir} pull-request --base master -p -F update-message.md

done

echo "***************************************"
echo "Finished!"
