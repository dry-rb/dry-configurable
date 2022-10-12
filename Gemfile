# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "dry-core", github: "dry-rb/dry-core", branch: "main"

group :benchmarks do
  gem "benchmark-ips"
  gem "benchmark-memory"
  gem "memory_profiler"

  gem "hanami-utils"
end

group :tools do
  gem "hotch", platform: :mri
  gem "pry-byebug", platform: :mri
  gem "rspec-benchmark"
end
