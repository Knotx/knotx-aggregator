#!/bin/bash

RELEASE_VERSION="1.6.0"

fail_fast_operation () {
  if (( $1 != 0 )); then
    echo "Operation: [$2] failed!" >&2
    exit 1
  fi
}

gitCommitAndCreateTag() {
  local project="$1"
  local version="$2"

  echo "Generating new vesion tag"
  git --git-dir=${project}/.git --work-tree=${project} add .
  git --git-dir=${project}/.git --work-tree=${project} commit -m "Releasing ${version}"
  git --git-dir=${project}/.git --work-tree=${project} tag ${version}
  git --git-dir=${project}/.git --work-tree=${project} push origin ${version}
}

releaseGradle() {
  local project="$1"
  local version="$2"

  # FixMe this requires `brew install gnu-sed`
  gsed -i "/version/c version=${version}" ${project}/gradle.properties

  echo "************************************************************"
  local project="$1"
  local version="$2"
  echo "Starting release of ${project} ${version}"

  # Set release version
  gsed -i "/version/c version=${version}" ${project}/gradle.properties

  ${project}/gradlew -p ${project} clean publishToMavenLocal publish -Dorg.gradle.internal.http.socketTimeout=300000 -Dorg.gradle.internal.http.connectionTimeout=60000
  # gitCommitAndCreateTag $project $version
  echo "************************************************************"
}

releaseMaven() {
  echo "************************************************************"
  local project="$1"
  local version="$2"
  echo "Starting release of ${project} ${version}"

  mvn -f ${project}/pom.xml versions:set -DnewVersion=${version} -DgenerateBackupPoms=false

  mvn -f ${project}/pom.xml clean deploy -Prelease
  # gitCommitAndCreateTag $project $version
  echo "************************************************************"
}

release() {
  releaseMaven "knotx-dependencies" ${RELEASE_VERSION}; fail_fast_operation $? "knotx-dependencies"
  releaseGradle "knotx-junit5" ${RELEASE_VERSION}; fail_fast_operation $? "knotx-junit5"
  releaseMaven "knotx" ${RELEASE_VERSION}; fail_fast_operation $? "knotx"
  releaseGradle "knotx-data-bridge" ${RELEASE_VERSION}; fail_fast_operation $? "knotx-data-bridge"
  releaseGradle "knotx-forms" ${RELEASE_VERSION}; fail_fast_operation $? "knotx-forms"
  releaseGradle "knotx-template-engine" ${RELEASE_VERSION}; fail_fast_operation $? "knotx-template-engine"
  releaseMaven "knotx-stack" ${RELEASE_VERSION}; fail_fast_operation $? "knotx-stack"
}

save() {
  gitCommitAndCreateTag "knotx-dependencies" ${RELEASE_VERSION}
  gitCommitAndCreateTag "knotx-junit5" ${RELEASE_VERSION}
  gitCommitAndCreateTag "knotx" ${RELEASE_VERSION}
  gitCommitAndCreateTag "knotx-data-bridge" ${RELEASE_VERSION}
  gitCommitAndCreateTag "knotx-forms" ${RELEASE_VERSION}
  gitCommitAndCreateTag "knotx-template-engine" ${RELEASE_VERSION}
  gitCommitAndCreateTag "knotx-stack" ${RELEASE_VERSION}
}

releaseDocker() {
  mvn -f knotx-stack/knotx-docker/pom.xml docker:push
}

echo "******** Releasing ${RELEASE_VERSION} ********"

# prevents "gpg: signing failed: Inappropriate ioctl for device"
export GPG_TTY=$(tty)

release
releaseDocker
save
