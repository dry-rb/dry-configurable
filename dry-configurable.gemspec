require File.expand_path('../lib/dry/configurable/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'dry-configurable'
  spec.version       = Dry::Configurable::VERSION
  spec.authors       = ['Andy Holland']
  spec.email         = ['andyholland1991@aol.com']
  spec.summary       = 'A mixin to add configuration functionality to your classes'
  spec.homepage      = 'https://github.com/dry-rb/dry-configurable'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec|bin)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = ">= 2.3.0"
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'dry-core', '~> 0.4', '>= 0.4.7'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
