$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name        = "files.com-mock-server"
  s.version     = File.open(File.expand_path('_VERSION', __dir__)).read
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ "files.com" ]
  s.email       = [ "support@files.com" ]
  s.homepage    = "https://www.files.com"
  s.summary     = "Files.com Mock API Server."
  s.description = "Mock Files.com Server API for your own Integration Testing."
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.5"
  s.add_dependency 'activesupport', ">= 6.0.3.2"
  s.add_dependency 'grape', ">= 1.3.3"
  s.add_dependency 'puma', ">= 4.3.5"
  s.add_dependency 'rubocop'

  s.files = `find *`.split("\n").uniq.sort.reject(&:empty?)
end
