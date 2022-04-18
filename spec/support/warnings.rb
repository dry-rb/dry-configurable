# frozen_string_literal: true

# this file is managed by dry-rb/devtools project

require "warning"

Warning.ignore(%r{rspec/core})
Warning.ignore(%r{rspec/mocks})
Warning.ignore(/codacy/)
Warning[:experimental] = false if Warning.respond_to?(:[])
