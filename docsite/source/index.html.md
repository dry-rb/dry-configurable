---
title: Introduction &amp; Usage
description: Thread-safe configuration mixin
layout: gem-single
order: 7
type: gem
name: dry-configurable
sections:
  - testing
---

### Introduction

`dry-configurable` is a simple mixin to add thread-safe configuration behaviour to your classes. There are many libraries that make use of configuration, and each seemed to have their own implementation with a similar or duplicate interface, so we thought it was strange that this behaviour had not already been encapsulated into a reusable gem, hence `dry-configurable` was born.

### Usage

`dry-configurable` is extremely simple to use, just extend the mixin and use the `setting` macro to add configuration options:

```ruby
class App
  extend Dry::Configurable

  # Pass a block for nested configuration (works to any depth)
  setting :database do
    # Can pass a default value
    setting :dsn, default: 'sqlite:memory'
  end
  # Defaults to nil if no default value is given
  setting :adapter
  # Construct values
  setting :path, default: 'test', constructor: proc { |value| Pathname(value) }
  # Passing the reader option as true will create attr_reader method for the class
  setting :pool, default: 5, reader: true
  # Passing the reader attributes works with nested configuration
  setting :uploader, reader: true do
    setting :bucket, default: 'dev'
  end
end

App.config.database.dsn
# => "sqlite:memory"

App.config.database.dsn = 'jdbc:sqlite:memory'
App.config.database.dsn
# => "jdbc:sqlite:memory"
App.config.adapter
# => nil
App.config.path
# => #<Pathname:test>
App.pool
# => 5
App.uploader.bucket
# => 'dev'
```

`dry-configurable` can also be used to pass a configuration block like you may have seen in
other gems. 

Example:

```ruby
class App
  extend Dry::Configurable
  setting :database
end

App.config.database # => nil

App.configure do |config|
  config.database = "postgres"
end

App.config.database # => "postgres"
```
