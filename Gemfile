source 'https://rubygems.org'

gem 'activesupport', '~> 7.2', '>= 7.2.3.1'
gem 'grape', '~> 3.1.1'
# The locked json 2.6.3, which RuboCop brings in and the server loads, requires ostruct, and Ruby 4.0
# no longer ships ostruct as a default gem.
gem 'ostruct', '~> 0.6'
gem 'puma', '~> 8.0', '>= 8.0.2'
gem 'puma-daemon', '~> 0.5', require: false
gem 'rack', '~> 3.2', '>= 3.2.7'
# Exact, and the same in the gemspec: setup.sh, build.sh and lint.sh format and check the generated code
# with this version, and the image installs it.
gem 'rubocop', '= 1.91.0'

group :test do
  # Explicit because the minitest locked through activesupport alone needs mutex_m, which Ruby 3.4 no longer ships by default.
  gem 'minitest', '~> 5.27'
end
