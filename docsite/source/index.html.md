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

`dry-configurable` is a simple mixin to add **thread-safe configuration** behavior to your classes. There are many libraries that make use of the configuration, and each seemed to have its own implementation with a similar or duplicate interface, so we thought it was strange that this behavior had not already been encapsulated into a reusable gem, hence `dry-configurable` was born.

### Usage

`dry-configurable` is extremely simple to use, just extend the mixin and use the `setting` macro to add configuration options:

#### Overview

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

#### Configuring different types of objects

With `dry-configurable`, **you can easily configure anything**, doesn't matter if you need to work with `module`, `class`, or an `instance of a class`

To configure a module or class, you need to extend the `Dry::Configurable` module.

```ruby
module MyModule
  extend Dry::Configurable

  setting :adapter
end

class MyClass
  extend Dry::Configurable

  setting :adapter
end

MyModule.config.adapter = :http
MyModule.config.adapter # => :http

MyClass.config.adapter = :tcp
MyClass.config.adapter # => :tcp
```

To configure an instance of a class, the only difference is that you need to `include` the `Dry::Configurable` instead of extending it.

```ruby
class MyClass
  include Dry::Configurable

  setting :adapter
end

foo = MyClass.new
bar = MyClass.new

foo.config.adapter = :grpc
bar.config.adapter = :http

foo.config.adapter #=> :grpc
bar.config.adapter #=> :http
```

#### Configure block syntax

There is an alternative way to configure your objects, using `configure` method. It sends the `config` instance to the block you pass as an argument and then yields whatever is inside.

```ruby
App.configure do |config|
  config.database.dsn = "sqlite:memory"
  config.adapter = :grpc
  config.pool = 5
  config.uploader.bucket = 'production'
end
```

The returned value is the object that the `configure` method is called upon. This means you can easily get multiple objects configured independently.

```ruby
class Client
  include Dry::Configurable

  setting :adapter, reader: true
end

client1 = Client.new.configure do |config|
  config.adapter :grpc
end

client2 = Client.new.configure do |config|
  config.adapter = :http
end

client1.adapter # => :grpc
client2.adapter # => :http
```
