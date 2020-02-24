#!/usr/bin/env bash

while getopts p option
do
  case "${option}"
    in
    p) PR=true;;
  esac
done


echo "Creating PRs automatically: [$PR]"

rm -rf knotx-repos

repos=()
IFS=$'\n' read -d '' -r -a repos < ../repositories.cfg

TIMESTAMP=`date "+%d%b%Y%H%M%S"`
BRANCH=feature/azure-pipeline-upgrade-$TIMESTAMP
DEFAULT_ORG="Knotx"

for project in "${repos[@]}"
do
  operation="Updating Azure Pipelines configuration: $DEFAULT_ORG/$project to knotx-repos/$project"
  echo "$operation"

  git clone --depth 1 "git@github.com:$DEFAULT_ORG/$project.git" "knotx-repos/$project"
  git --git-dir=knotx-repos/${project}/.git --work-tree=knotx-repos/${project} checkout -b $BRANCH

  cp "./azure-pipelines.yml" "knotx-repos/$project"

  git --git-dir=knotx-repos/${project}/.git --work-tree=knotx-repos/${project} add .
  git --git-dir=knotx-repos/${project}/.git --work-tree=knotx-repos/${project} commit -m "Update Azure Pipelines configuration."
  if [[ $PR ]]; then
    hub --git-dir=knotx-repos/${project}/.git --work-tree=knotx-repos/${project} pull-request --base master -p -F update-message.md
  else
    git --git-dir=knotx-repos/${project}/.git --work-tree=knotx-repos/${project} push origin $BRANCH
    echo "Remember to create Pull Request on ${project}!"
  fi

done

echo "***************************************"
echo "Finished!"
