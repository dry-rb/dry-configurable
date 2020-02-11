# frozen_string_literal: true

require 'rspec/core/rake_task'

desc 'Run all specs in spec directory'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--pattern spec/integration/**/*_spec.rb'
end

task default: :spec
