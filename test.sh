#!/usr/bin/env ruby
# Tests generated code as emitted, without formatting it. Lint/Security checks still detect syntax and code defects;
# release preparation (build.sh) applies formatting and the full style check. Runtime tests start real Puma processes
# on ephemeral loopback ports and stop them before exiting. Use this app's bundle, preserving caller Bundler settings.
require "bundler"

Bundler.with_original_env do
  ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", __dir__)
  Dir.chdir(__dir__) do
    exit 1 if ARGV[0] == "true" && !system("bundle", "install")
    checked = system(File.join(__dir__, "lint.sh"), "--only", "Lint,Security")
    tested = system("bundle", "exec", "ruby", "test/run.rb")
    exit(checked && tested ? 0 : 1)
  end
end
