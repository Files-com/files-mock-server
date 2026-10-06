#!/usr/bin/env ruby
# Builds the generated mock server as CI does (.gitlab-ci/build-target.sh runs it here): installs the
# bundle, applies RuboCop's safe autocorrections (the formatting setup.sh also applies during
# generation), then checks the formatted files without changing them (lint.sh). Any failing step
# fails the build with that step's exit status. Like setup.sh and test.sh, it uses this app's own
# bundle, not the generator's that `bundle exec` passes down, and keeps the caller's own Bundler
# settings.
require "bundler"
require "English"

Bundler.with_original_env do
  ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", __dir__)
  Dir.chdir(__dir__) do
    [ %w[bundle install], %w[bundle exec rubocop --format simple -a --ignore-parent-exclusion], [ File.join(__dir__, "lint.sh") ] ].each do |step|
      next if system(*step)

      exit($CHILD_STATUS.exitstatus || 1)
    end
  end
end
