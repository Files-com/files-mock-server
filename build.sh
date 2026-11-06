#!/usr/bin/env ruby
# Prepares generated code for release: install this app's bundle, apply safe formatting corrections, then require
# the full lint check to pass. Test-only generation uses setup.sh and never runs the formatter.
require "bundler"
require "English"

Bundler.with_original_env do
  ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", __dir__)
  Dir.chdir(__dir__) do
    steps = [ %w[bundle install --quiet],
              %w[bundle exec rubocop --cache false --format simple -a --ignore-parent-exclusion --fail-level error],
              [ File.join(__dir__, "lint.sh") ] ]
    steps.each do |step|
      next if system(*step)

      exit($CHILD_STATUS.exitstatus || 1)
    end
  end
end
