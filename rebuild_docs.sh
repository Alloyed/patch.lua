#!/bin/bash

set -o errexit -o nounset

rev=$(git rev-parse --short HEAD)

$HOME/.luarocks/bin/ldoc -d $CIRCLE_ARTIFACTS/docs .

cp circle.yml $CIRCLE_ARTIFACTS/docs

cd $CIRCLE_ARTIFACTS/docs

git init
git config user.name "CircleCI"
git config user.email "kjmclamb+circleci@gmail.com"

git remote add upstream "https://$GH_API@github.com/Alloyed/patch.lua.git"
git fetch upstream
git reset upstream/gh-pages

git add -A .
git commit -m "rebuild pages at ${rev} via CircleCI"
git push -q upstream HEAD:gh-pages

rm -rf .git
