# Loads every runtime test. Finding no tests is a failure, not a pass.
test_files = Dir[File.join(__dir__, "**", "*_test.rb")]
abort "No runtime tests found in #{__dir__}" if test_files.empty?

require "minitest/autorun"
test_files.sort.each { |file| require file }
