#!/usr/bin/env ruby
# Checks this generated mock server with its own RuboCop (lint.sh, which also fails when RuboCop finds no
# files to check) and runs its runtime tests, without modifying its files; either failing fails this
# script. The check reports any offense setup.sh could not auto-fix. The tests start real Puma processes
# on ephemeral loopback ports and stop them before exiting. Like setup.sh, it uses this app's own bundle,
# not the generator's that `bundle exec` passes down, and keeps the caller's own Bundler settings. The
# generator passes "true" on its first run so this app's bundle is installed first.
require "bundler"

Bundler.with_original_env do
  ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", __dir__)
  Dir.chdir(__dir__) do
    exit 1 if ARGV[0] == "true" && !system("bundle", "install")
    checked = system(File.join(__dir__, "lint.sh"))
    tested = system("bundle", "exec", "ruby", "test/run.rb")
    exit(checked && tested ? 0 : 1)
  end
end
