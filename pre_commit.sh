#!/usr/bin/env sh
# push_release.rb invokes this hook in the mock-server mirror before deciding, committing or pushing a release.
set -eu
./build.sh
git add .
