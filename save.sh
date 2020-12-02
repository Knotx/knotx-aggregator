#!/bin/bash

declare -a repos=("knotx-dependencies" "knotx" "knotx-junit5" "knotx-data-bridge" "knotx-forms" "knotx-template-engine" "knotx-stack")
BRANCH="release/1.6-rc-1"

while getopts m:p option
do
  case "${option}"
    in
    m) MESSAGE=${OPTARG};;
    p) PUSH=true;;
  esac
done

echo "Commit message [$MESSAGE]"

for project in "${repos[@]}"
do
  projectDir="${project}"
  echo "Saving $project ..."

  git --git-dir=${projectDir}/.git --work-tree=${projectDir} add .
  git --git-dir=${projectDir}/.git --work-tree=${projectDir} commit -m "${MESSAGE}"
  if [[ $PUSH ]]; then
    echo " !!! Pushing changes"
    git --git-dir=${projectDir}/.git --work-tree=${projectDir} push -u origin ${BRANCH}
  fi
done
