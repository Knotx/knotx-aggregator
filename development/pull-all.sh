#!/usr/bin/env bash

# eval ssh
# eval `ssh-agent`
# ssh-add ~/.ssh/id_rsa


#########################
# The command line help #
#########################
help() {
    echo "Usage: $0 [option...] {start|stop|restart}" >&2
    echo
    echo "   -r                         root folder path for all cloned repositories"
    echo "   -b                         GIT branch name"
    echo "   -c                         create GIT branch if not exists"
    echo "   -f                         reset all changes if repository is cloned"
    echo
    echo "Examples:"
    echo "   sh pull-all.sh -r projects/knotx -b master                     clone (if not exists) all repositories to 'projects/knotx' folder and switch to master branch"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -c     clone (if not exists) all repositories to 'projects/knotx' folder and switch to 'feature/some-branch' (if not exists create the branch)"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -f     clone (if not exists) all repositories to 'projects/knotx' folder and switch to 'feature/some-branch' (discard all modifications)"
    # echo some stuff here for the -a or --add-options
    exit 1
}

while getopts hr:b:fc option
do
  case "${option}"
    in
    h) help;;
    r) ROOT=${OPTARG};;
    b) BRANCH=${OPTARG};;
    f) FORCE=true;;
    c) CREATE=true;;
  esac
done

echo "Script root catalogue [$ROOT]"

if [[ $FORCE ]]; then
  while true; do
    read -p "Do you wish to RESET all changes in all repositories to HEAD and switch to [$BRANCH] [yes/no]? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Script NOT executed!"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
  done
fi

cd $ROOT

checkout() {
  # $1 organization
  # $2 repository name
  echo "Checking out git@github.com:$1/$2.git"

  if [[ -d $2 ]]; then
    if [[ $FORCE ]]; then
      git --git-dir=$2/.git --work-tree=$2 reset HEAD --force
    fi
    git --git-dir=$2/.git --work-tree=$2 fetch
  else
    git clone "git@github.com:$1/$2.git"
  fi
  git --git-dir=$2/.git --work-tree=$2 checkout master
  if [[ `git --git-dir=$2/.git --work-tree=$2 branch --list --all | grep $BRANCH` ]]; then
    git --git-dir=$2/.git --work-tree=$2 checkout $BRANCH
  else
    if [[ $CREATE ]]; then
      git --git-dir=$2/.git --work-tree=$2 checkout -b $BRANCH
    fi
  fi
  git --git-dir=$2/.git --work-tree=$2 pull
}

checkout 'Knotx' 'knotx-junit5'
checkout 'Cognifide' 'knotx'
checkout 'Knotx' 'knotx-dependencies'
checkout 'Knotx' 'knotx-forms'
checkout 'Knotx' 'knotx-data-bridge'
checkout 'Knotx' 'knotx-stack'
checkout 'Knotx' 'knotx-example-project'

echo "Finished!"