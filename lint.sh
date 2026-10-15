#!/usr/bin/env bash
# Checks this generated mock server with RuboCop under its .rubocop.yml without changing any file.
# Formatting happens during generation: setup.sh applies RuboCop's safe autocorrections, and this
# checks what it produced; test.sh and build.sh both run it. It fails on any offense, on a RuboCop
# or bundle error, and when RuboCop finds no files to check. Run it from any directory once the bundle
# is installed.
set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )"

targets=$(bundle exec rubocop --list-target-files --ignore-parent-exclusion)
if [[ -z "$targets" ]]; then
  echo "lint.sh: RuboCop found no files to check" >&2
  exit 1
fi
bundle exec rubocop --cache false --format simple --ignore-parent-exclusion
