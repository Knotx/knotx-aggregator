#!/usr/bin/env bash

# eval ssh
# eval `ssh-agent`
# ssh-add ~/.ssh/id_rsa

while getopts hr:b:fcm:a option
do
  case "${option}"
    in
    h) help;;
    r) ROOT=${OPTARG};;
    b) BRANCH=${OPTARG};;
    f) FORCE=true;;
    c) CREATE=true;;
    m) MERGE=${OPTARG};;
    a) HTTPS=true;;
  esac
done

echo "Script root catalogue [$ROOT]"
echo "GIT branch name [$BRANCH]"

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

#########################
# The command line help #
#########################
help() {
    echo "Usage: $0 [option...] " >&2
    echo
    echo "   -r                         root folder path for all cloned repositories"
    echo "   -b                         GIT branch name"
    echo "   -c                         create GIT branch if not exists and sets the tracking"
    echo "   -f                         reset all changes if repository is cloned"
    echo "   -m                         merge / rebase with branch '-m original/master'"
    echo
    echo "Examples:"
    echo "   sh pull-all.sh -r projects/knotx -b master                                   clones (if not exists) all repositories to 'projects/knotx' folder and switches to master branch"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -c                   clones (if not exists) all repositories to 'projects/knotx' folder and switches to 'feature/some-branch' (if not exists create the branch)"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -f                   clones (if not exists) all repositories to 'projects/knotx' folder and switches to 'feature/some-branch' (discard all modifications)"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -m origin/master     clones (if not exists) all repositories to 'projects/knotx' folder, switches to 'feature/some-branch', rebases with 'origin/master', pushes changes"
    exit 1
}

############################
# GIT checkout with branch #
############################
checkout() {
  # $1 organization
  # $2 repository name
  echo "***************************************"
  echo "* Checking out git@github.com:$1/$2.git"
  echo "***************************************"

  if [[ -d $2 ]]; then
    if [[ $FORCE ]]; then
      git --git-dir=$2/.git --work-tree=$2 reset HEAD --hard
    fi
    git --git-dir=$2/.git --work-tree=$2 fetch
  else
    if [[ $HTTPS ]]; then
      git clone "https://github.com/$1/$2.git"
    else
      git clone "git@github.com:$1/$2.git"
    fi
  fi

  git --git-dir=$2/.git --work-tree=$2 checkout master
  git --git-dir=$2/.git --work-tree=$2 pull

  # checks if branch exists, otherwise use master branch
  if [[ `git --git-dir=$2/.git --work-tree=$2 branch --list --all | grep $BRANCH` ]]; then
    git --git-dir=$2/.git --work-tree=$2 checkout $BRANCH
    if [[ $MERGE ]]; then
      git --git-dir=$2/.git --work-tree=$2 rebase $MERGE
      git --git-dir=$2/.git --work-tree=$2 push
    fi
  else
    if [[ $CREATE ]]; then
      git --git-dir=$2/.git --work-tree=$2 checkout -b $BRANCH
      if [[ $MERGE ]]; then
        git --git-dir=$2/.git --work-tree=$2 rebase $MERGE
        git --git-dir=$2/.git --work-tree=$2 push
      fi
      git --git-dir=$2/.git --work-tree=$2 branch --set-upstream-to=origin/$BRANCH $BRANCH
    fi
  fi
  git --git-dir=$2/.git --work-tree=$2 pull
}

#########################
#       Execute         #
#########################

repos=()
IFS=$'\n' read -d '' -r -a repos < ../repositories.cfg

cd $ROOT

org=''
project=''
for repo in "${repos[@]}"
do
  org=`echo "$repo" | cut -d';' -f1`
  project=`echo "$repo" | cut -d';' -f2`
  checkout $org $project
done

echo "***************************************"
echo "SUMMARY"
echo "***************************************"

for repo in "${repos[@]}"
do
  org=`echo "$repo" | cut -d';' -f1`
  project=`echo "$repo" | cut -d';' -f2`
  printf "%-30s %s\n" "$org/$project" `git --git-dir=$project/.git --work-tree=$project branch | grep \* | cut -d ' ' -f2`
done

# allows to import all modules in IDEA as one project
touch knotx-stack/.composite-enabled

echo "***************************************"
echo "Finished!"
