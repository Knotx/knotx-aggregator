#!/bin/bash

# eval ssh
# eval `ssh-agent`
# ssh-add ~/.ssh/id_rsa

DEFAULT_ORG="Knotx"

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
    echo "   -o                         organization '-o Knotx' - this option works only when repository was not cloned already"
    echo "   -a                         clone with HTTPS instead of clone with SSH (defult)"
    echo
    echo "Examples:"
    echo "   sh pull-all.sh -r projects/knotx -b master                                   clones (if not exists) all repositories to 'projects/knotx' folder and switches to master branch"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -c                   clones (if not exists) all repositories to 'projects/knotx' folder and switches to 'feature/some-branch' (if not exists create the branch)"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -f                   clones (if not exists) all repositories to 'projects/knotx' folder and switches to 'feature/some-branch' (discard all modifications)"
    echo "   sh pull-all.sh -r projects/knotx -b feature/some-branch -m origin/master     clones (if not exists) all repositories to 'projects/knotx' folder, switches to 'feature/some-branch', rebases with 'origin/master', pushes changes"
    echo "   sh pull-all.sh -r projects/knotx -b master -o Custom                         clones (if not exists) all repositories from https://github.com/Custom (instead of https://github.com/Knotx, which is fallback when Custom does not contain the repo) organization to 'projects/knotx' folder and switches to master branch"
    exit 1
}

############################
# GIT checkout with branch #
############################
checkout() {
  GITHUB_ORG=$1
  GITHUB_REPO=$2

  echo "***************************************"
  echo "* Checking out git@github.com:$GITHUB_ORG/$GITHUB_REPO.git"
  echo "***************************************"

  if [[ -d $GITHUB_REPO ]]; then
    if [[ $FORCE ]]; then
      git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO reset HEAD --hard
    fi
    git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO fetch
  else

    status="$(curl -s --head -w %{http_code} "https://github.com/$GITHUB_ORG/$GITHUB_REPO" -o /dev/null)"
    if [ $status != "200" ]; then
      echo "Can't access https://github.com/$GITHUB_ORG/$GITHUB_REPO, will clone https://github.com/$DEFAULT_ORG/$GITHUB_REPO instead"
      GITHUB_ORG=$DEFAULT_ORG
    fi

    if [[ $HTTPS ]]; then
      git clone "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
    else
      git clone "git@github.com:$GITHUB_ORG/$GITHUB_REPO.git"
    fi
  fi

  git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO checkout master
  git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO pull

  # checks if branch exists, otherwise use master branch
  if [[ `git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO branch --list --all | grep $BRANCH` ]]; then
    git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO checkout $BRANCH
    if [[ $MERGE ]]; then
      git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO rebase $MERGE
      git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO push
    fi
  else
    if [[ $CREATE ]]; then
      git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO checkout -b $BRANCH
      if [[ $MERGE ]]; then
        git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO rebase $MERGE
        git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO push
      fi
      git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO branch --set-upstream-to=origin/$BRANCH $BRANCH
    fi
  fi
  git --git-dir=$GITHUB_REPO/.git --work-tree=$GITHUB_REPO pull
}

#########################
#          Main         #
#########################

while getopts hr:b:fcm:o:a option
do
  case "${option}"
    in
    h) help;;
    r) ROOT=${OPTARG};;
    b) BRANCH=${OPTARG};;
    f) FORCE=true;;
    c) CREATE=true;;
    m) MERGE=${OPTARG};;
    o) ORGANIZATION=${OPTARG};;
    a) HTTPS=true;;
  esac
done

ORG="${ORGANIZATION:-$DEFAULT_ORG}"

echo "Script root catalogue [$ROOT]"
echo "GitHub organization [$ORG ($ORGANIZATION)]"
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
#       Execute         #
#########################

repos=()
IFS=$'\n' read -d '' -r -a repos < ../repositories.cfg

cd $ROOT

for repo in "${repos[@]}"
do
  checkout $ORG $repo
done

echo "***************************************"
echo "SUMMARY"
echo "***************************************"

echo `pwd`
for repo in "${repos[@]}"
do
  repo_url=$(git --git-dir=$repo/.git --work-tree=$repo config --get remote.origin.url 2>&1)
  if [[ $repo_url == http* ]]; then
    origin=`echo $repo_url | cut -d'.' -f2 | cut -c 5-`
  else
    origin=`echo $repo_url | cut -d':' -f2 | cut -d'.' -f1`
  fi

  repo_org=$(cut -d'/' -f1 <<<$origin)
  repo_name=$(cut -d'/' -f2 <<<$origin)
  branch=`git --git-dir=$repo/.git --work-tree=$repo branch | grep \* | cut -d ' ' -f2`

  printf "%10s %30s %20s %s\n" $repo_org $repo_name $branch
done

# allows to import all modules in IDEA as one project
touch knotx-stack/.composite-enabled

echo "***************************************"
echo "Finished!"