#!/usr/bin/env bash

bundle install && bundle exec rubocop -a --ignore-parent-exclusion >/dev/null 2>/dev/null
