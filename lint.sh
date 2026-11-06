#!/usr/bin/env bash
# Checks generated Ruby without modifying files; rejects empty selections and propagates RuboCop/bundle failures.
# No arguments checks all cops for releases; test.sh selects syntax, Lint and Security checks only.
set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )"

targets=$(bundle exec rubocop --list-target-files --ignore-parent-exclusion "$@")
if [[ -z "$targets" ]]; then
  echo "lint.sh: RuboCop found no files to check" >&2
  exit 1
fi
bundle exec rubocop --cache false --format simple --ignore-parent-exclusion "$@"
