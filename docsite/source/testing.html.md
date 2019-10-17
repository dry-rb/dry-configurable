---
title: Testing
layout: gem-single
name: dry-configurable
---

### How to reset the config to its original state on testing environment

update `spec_helper.rb` :

```ruby
require "dry/configurable/test_interface"

# this is your module/class that extended by Dry::Configurable
module AwesomeModule
  enable_test_interface
end
```

and on spec file (`xxx_spec.rb`) :

```ruby 
before(:all) { AwesomeModule.reset_config }
# or 
before(:each) { AwesomeModule.reset_config }

```
