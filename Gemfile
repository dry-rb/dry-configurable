# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

group :benchmarks do
  gem "benchmark-ips"
end

group :tools do
  gem "hotch"
  gem "pry-byebug", platform: :mri
end
