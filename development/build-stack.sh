#!/usr/bin/env bash

#########################
# The command line help #
#########################
help() {
    echo "Usage: $0 [option...] " >&2
    echo
    echo "   -r                         root folder with cloned repositories"
    echo "   -d                         deploy to maven central snapshots"
    echo "   -i                         also builds knotx base docker image"
    echo
    echo "Examples:"
    echo "   sh build-stack.sh -r projects/knotx -d                           rebuild all repositories defined in ../repositories.cfg and deploy artifacts to maven snapshot"
    exit 1
}

fail_fast_build () {
  if (( $1 != 0 )); then
    echo "Building [$2] failed!" >&2
    exit 1
  fi
}

############################
#       Maven build        #
############################
build_with_maven () {
  # S1 root folder
  # $2 deploy
  echo "***************************************"
  echo "* Building [$1] using maven with deploy [$2]"
  echo "***************************************"
  if [[ $2 ]]; then
    mvn -f $1/pom.xml clean install deploy; fail_fast_build $? $1
  else
    mvn -f $1/pom.xml clean install; fail_fast_build $? $1
  fi
}

############################
#      Gradle build        #
############################
build_composite_with_gradle () {
  # $1 root folder
  # $2 deploy
  echo "***************************************"
  echo "* Building [$1] using gradle with deploy [$2]"
  echo "***************************************"
  $1/gradlew -p $1 clean build --rerun-tasks; fail_fast_build $? $1

  echo "***************************************"
  echo "* Publishing [$1]"
  echo "***************************************"
  if [[ $2 ]]; then
    $1/gradlew -p $1 publish-all; fail_fast_build $? $1
  else
    $1/gradlew -p $1 --info --rerun-tasks publish-local-all; fail_fast_build $? $1
  fi
}

############################
#       Build docker       #
############################
build_docker_with_maven () {
  echo "***************************************"
  echo "* Building [$1] using maven"
  echo "***************************************"
  mvn -f $1/pom.xml clean package; fail_fast_build $? $1
}

#########################
#         Main          #
#########################

while getopts hr:di option
do
  case "${option}"
    in
    h) help;;
    r) ROOT=${OPTARG};;
    d) DEPLOY=true;;
    i) DOCKER_IMAGE=true;;
  esac
done

#########################
#       Execute         #
#########################
cd ${ROOT}
touch ${ROOT}/knotx-stack/.composite-enabled

knotx-gradle-plugins/gradlew -p knotx-gradle-plugins publishToMavenLocal; fail_fast_build $? true
build_composite_with_gradle `echo "knotx-stack" | cut -d';' -f2` $DEPLOY

if [[ $DOCKER_IMAGE ]]; then
  build_docker_with_maven `echo "knotx-docker"`
fi

echo "Finished!"
