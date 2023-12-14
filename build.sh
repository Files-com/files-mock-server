#!/usr/bin/env bash

bundle install && bundle exec rubocop --format simple -a --ignore-parent-exclusion
