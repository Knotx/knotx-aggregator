#!/usr/bin/env bash

PROJECT="$1"
VERSION="$2"
export GPG_TTY=$(tty)

X="1"

# Set release version
sed -i "${X}s/.*/version=${VERSION}/g" knotx-repos/${PROJECT}/gradle.properties

# Release
knotx-repos/${PROJECT}/gradlew publish

git --git-dir=knotx-repos/${PROJECT}/.git --work-tree=knotx-repos/${PROJECT} add .
git --git-dir=knotx-repos/${PROJECT}/.git --work-tree=knotx-repos/${PROJECT} commit -m "Releasing ${VERSION}"
git --git-dir=knotx-repos/${PROJECT}/.git --work-tree=knotx-repos/${PROJECT} tag ${VERSION}