#!/bin/bash

declare -a repos=("knotx-dependencies" "knotx-junit5" "knotx" "knotx-data-bridge" "knotx-forms" "knotx-template-engine" "knotx-stack")
ORGANISATION="Knotx"
BRANCH="release/1.6-rc-1"

cloneAll() {
  for r in "${repos[@]}"
  do
    git clone git@github.com:${ORGANISATION}/${r}.git
  done
}

checkoutBranchFromTag() {
  for r in "${repos[@]}"
  do
    echo "Checking out branch for ${r}"
    git --git-dir=${r}/.git --work-tree=${r} checkout 1.5.0 -b ${BRANCH}
  done
}

setUpgradeBranch() {
  for r in "${repos[@]}"
  do
    echo "Checking out branch for ${r}"
    git --git-dir=${r}/.git --work-tree=${r} checkout ${BRANCH}
  done
}

setVersionWithMaven() {
  local project="$1"
  local version="$2"

  mvn -f ${project}/pom.xml versions:set -DnewVersion=${version} -DgenerateBackupPoms=false
}

setVersionWithGradle() {
  local project="$1"
  local version="$2"

  # FixMe this requires `brew install gnu-sed`
  gsed -i "/version/c version=${version}" ${project}/gradle.properties
}

setVersions() {
  setVersionWithMaven "knotx-dependencies" "1.5.1-SNAPSHOT"
  setVersionWithMaven "knotx" "1.5.1-SNAPSHOT"
  setVersionWithGradle "knotx-junit5" "1.5.1-SNAPSHOT"
  setVersionWithGradle "knotx-data-bridge" "1.5.1-SNAPSHOT"
  setVersionWithGradle "knotx-forms" "1.5.1-SNAPSHOT"
  setVersionWithGradle "knotx-template-engine" "1.5.1-SNAPSHOT"
  setVersionWithMaven "knotx-stack" "1.5.1-SNAPSHOT"
}

updateRemotes() {
  for r in "${repos[@]}"
  do
    echo "Updating remote in ${r}"
    git --git-dir=${r}/.git --work-tree=${r} remote add fixorigin git@github.com:Knotx/${r}.git
    git --git-dir=${r}/.git --work-tree=${r} remote rename origin oldorigin
    git --git-dir=${r}/.git --work-tree=${r} remote rename fixorigin origin
    git --git-dir=${r}/.git --work-tree=${r} remote rm oldorigin
  done
}

cloneAll
# checkoutBranchFromTag
setUpgradeBranch
# setVersions
# updateRemotes
