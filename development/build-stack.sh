#!/usr/bin/env bash

#########################
# The command line help #
#########################
help() {
    echo "Usage: $0 [option...] " >&2
    echo
    echo "   -r                         root folder with cloned repositories"
    echo "   -i                         build base docker image"
    echo "   -s                         build starter kit project"
    echo "   -a                         audit dependencies"
    echo
    echo "Examples:"
    echo "   sh build-stack.sh -r projects/knotx -i -s                        rebuild all repositories defined in ../repositories.cfg and deploy artifacts to maven local repository, rebuild docker image, rebuild starter kit project"
    exit 1
}

fail_fast_build () {
  if (( $1 != 0 )); then
    echo "Building [$2] failed!" >&2
    exit 1
  fi
}

############################
#      Gradle build        #
############################
build() {
  # $1 root folder
  echo "***************************************"
  echo "* Building [$1]"
  echo "* Audit    [$2]"
  echo "***************************************"
  $1/gradlew -p $1 clean build $2 --rerun-tasks; fail_fast_build $? $1
}

publish() {
  # $1 root folder
  # $2 deploy
  echo "***************************************"
  echo "* Publishing [$1]"
  echo "* Deploy     [$2]"
  echo "***************************************"
  if [[ $2 ]]; then
    $1/gradlew -p $1 publish-all; fail_fast_build $? $1
  else
    $1/gradlew -p $1 --info --rerun-tasks publish-local-all; fail_fast_build $? $1
  fi
}

#########################
#         Main          #
#########################

while getopts hr:isa option
do
  case "${option}"
    in
    h) help;;
    r) ROOT=${OPTARG};;
    i) DOCKER_IMAGE=true;;
    s) STARTER_KIT=true;;
    a) AUDIT=-Paudit.enabled;;
  esac
done

#########################
#       Execute         #
#########################
cd ${ROOT}
touch knotx-stack/.composite-enabled

build knotx-stack $AUDIT
publish knotx-stack $DEPLOY

if [[ $DOCKER_IMAGE ]]; then
  build knotx-docker
fi

if [[ $STARTER_KIT ]]; then
  build knotx-starter-kit
fi

echo "Finished!"
