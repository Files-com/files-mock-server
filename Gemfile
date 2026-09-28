source 'https://rubygems.org'

gem 'activesupport', '~> 7.2', '>= 7.2.3.1'
gem 'grape', '~> 3.1.1'
gem 'puma', '~> 8.0', '>= 8.0.2'
gem 'puma-daemon', '~> 0.5', require: false
gem 'rack', '~> 3.2', '>= 3.2.7'
gem 'rubocop'

group :test do
  # Explicit because the minitest locked through activesupport alone needs mutex_m, which Ruby 3.4 no longer ships by default.
  gem 'minitest', '~> 5.27'
end
