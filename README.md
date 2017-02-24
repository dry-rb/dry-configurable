[gitter]: https://gitter.im/dry-rb/chat
[gem]: https://rubygems.org/gems/dry-configurable
[travis]: https://travis-ci.org/dry-rb/dry-configurable
[code_climate]: https://codeclimate.com/github/dry-rb/dry-configurable
[inch]: http://inch-ci.org/github/dry-rb/dry-configurable

# dry-configurable [![Join the Gitter chat](https://badges.gitter.im/Join%20Chat.svg)][gitter]

[![Gem Version](https://img.shields.io/gem/v/dry-configurable.svg)][gem]
[![Build Status](https://img.shields.io/travis/dry-rb/dry-configurable.svg)][travis]
[![Code Climate](https://img.shields.io/codeclimate/github/dry-rb/dry-configurable.svg)][code_climate]
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/dry-rb/dry-configurable.svg)][code_climate]
[![API Documentation Coverage](http://inch-ci.org/github/dry-rb/dry-configurable.svg)][inch]

## Synopsis

```ruby
class App
  extend Dry::Configurable

  # Pass a block for nested configuration (works to any depth)
  setting :database do
    # Can pass a default value
    setting :dsn, 'sqlite:memory'
  end
  # Defaults to nil if no default value is given
  setting :adapter
  # Passing the reader option as true will create reader method for the class
  setting :pool, 5 , reader: true
  # Passing the reader attributes works with nested configuration
  setting :uploader, nil, reader: true do
    setting :bucket, 'dev'
  end
end

App.configure do |config|
  config.database.dsn = 'jdbc:sqlite:memory'
end

App.config.database.dsn
# => 'jdbc:sqlite:memory'
App.config.adapter # => nil
App.pool # => 5
App.uploader.bucket # => 'dev'
```

## Links

* [Documentation](http://dry-rb.org/gems/dry-configurable)

## License

See `LICENSE` file.
