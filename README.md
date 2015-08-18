# dry-configurable <a href="https://gitter.im/dryrb/chat" target="_blank">![Join the chat at https://gitter.im/dryrb/chat](https://badges.gitter.im/Join%20Chat.svg)</a>

<a href="https://rubygems.org/gems/dry-configurable" target="_blank">![Gem Version](https://badge.fury.io/rb/dry-configurable.svg)</a>
<a href="https://travis-ci.org/dryrb/dry-configurable" target="_blank">![Build Status](https://travis-ci.org/dryrb/dry-configurable.svg?branch=master)</a>
<a href="https://gemnasium.com/dryrb/dry-configurable" target="_blank">![Dependency Status](https://gemnasium.com/dryrb/dry-configurable.svg)</a>
<a href="https://codeclimate.com/github/dryrb/dry-configurable" target="_blank">![Code Climate](https://codeclimate.com/github/dryrb/dry-configurable/badges/gpa.svg)</a>
<a href="http://inch-ci.org/github/dryrb/dry-configurable" target="_blank">![Documentation Status](http://inch-ci.org/github/dryrb/dry-configurable.svg?branch=master&style=flat)</a>


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
end

App.configure do |config|
  config.database.dsn = 'jdbc:sqlite:memory'
end

App.config.database.dsn
# => 'jdbc:sqlite:memory'
App.config.adapter # => nil
```

## License

See `LICENSE` file.
