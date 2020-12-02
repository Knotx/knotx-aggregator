#!/bin/bash

declare -a repos=("knotx-dependencies" "knotx-junit5" "knotx" "knotx-data-bridge" "knotx-forms" "knotx-template-engine" "knotx-stack")

fail_fast_operation () {
  if (( $1 != 0 )); then
    echo "Operation: [$2] failed!" >&2
    exit 1
  fi
}

buildWithMaven() {
  local project="$1"
  mvn -f ${project}/pom.xml clean install -DskipDocker
}

buildWithGradle() {
  local project="$1"
  ${project}/gradlew -p ${project} publishToMavenLocal
}

buildAll() {
  buildWithMaven "knotx-dependencies"; fail_fast_operation $? "knotx-dependencies"
  buildWithMaven "knotx"; fail_fast_operation $? "knotx-core"
  buildWithGradle "knotx-junit5"; fail_fast_operation $? "knotx-junit5"
  buildWithGradle "knotx-data-bridge"; fail_fast_operation $? "knotx-data-bridge"
  buildWithGradle "knotx-forms"; fail_fast_operation $? "knotx-forms"
  buildWithGradle "knotx-template-engine"; fail_fast_operation $? "knotx-template-engine"
  buildWithMaven "knotx-stack"; fail_fast_operation $? "knotx-stack"
}

buildAll
