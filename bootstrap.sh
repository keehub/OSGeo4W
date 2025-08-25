#!/bin/bash

set -e
export http_proxy="http://127.0.0.1:10809"
export https_proxy="http://127.0.0.1:10809"
export PATH=/bin:/usr/bin:$(/bin/cygpath --sysdir)

: ${O4W_GIT_REPO:=https://github.com/keehub/OSGeo4W}
: ${O4W_GIT_BRANCH:=master}

mkdir -p $HOME

git config --global --add safe.directory $PWD

# [ -d .git ] || {
# 	git init .
# 	git remote add origin $O4W_GIT_REPO
# 	git fetch origin
# 	rm -f bootstrap.sh
# 	git checkout -f -t origin/$O4W_GIT_BRANCH
# }

# [ -n "$CI" ] || git pull --rebase

bash scripts/build.sh "$@"
# bash scripts/regen.sh "$@"
# bash scripts/msis.sh "$@"
