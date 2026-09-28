#!/usr/bin/env ruby
# Runs the runtime tests against this generated mock server without modifying its files. The tests
# start real Puma processes on ephemeral loopback ports and stop them before exiting.
# The generator passes "true" on its first run so this app's bundle is installed first.
require "bundler"

Bundler.with_unbundled_env do
  Dir.chdir(__dir__) do
    exit 1 if ARGV[0] == "true" && !system("bundle", "install")
    exit(system("bundle", "exec", "ruby", "test/run.rb") ? 0 : 1)
  end
end
