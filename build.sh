#!/usr/bin/env ruby
# Checks this generated mock server with its own RuboCop, as test.sh does, without modifying its files, and
# fails on any offense. Like setup.sh, it uses this app's own bundle, not the generator's that `bundle exec`
# passes down, and keeps the caller's own Bundler settings.
require "bundler"
require "English"

Bundler.with_original_env do
  ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", __dir__)
  Dir.chdir(__dir__) do
    [ %w[bundle install], [ File.join(__dir__, "lint.sh") ] ].each do |step|
      next if system(*step)

      exit($CHILD_STATUS.exitstatus || 1)
    end
  end
end
