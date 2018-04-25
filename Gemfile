source 'https://rubygems.org'

gemspec

gem 'dry-container', git: 'https://github.com/dry-rb/dry-container.git', branch: 'master'
gem 'dry-struct', git: 'https://github.com/dry-rb/dry-struct.git', branch: 'master'
gem 'dry-types', git: 'https://github.com/dry-rb/dry-types.git', branch: 'master'

group :test do
  platforms :mri do
    gem 'codeclimate-test-reporter', require: false
    gem 'simplecov', require: false
  end
end

group :tools do
  gem 'guard'
  gem 'guard-rspec'
  gem 'listen', '3.0.6'
end
