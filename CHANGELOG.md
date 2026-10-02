# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Break Versioning](https://www.taoensso.com/break-versioning).

## [Unreleased]

### Added

- Add `type:` as an alias for `constructor:` when defining settings.

### Changed

### Deprecated

### Removed

### Fixed

### Security

[Unreleased]: https://github.com/dry-rb/dry-configurable/compare/v1.4.0...main

## [1.4.0] - 2026-05-13

### Added

- Added `Config#to_data`, returning a frozen `Data` representation of the config's resolved values for performance-sensitive read paths. (@cllns in #167)

### Changed

- Set minimum Ruby version to 3.3. (@alassek & @timriley)

[1.4.0]: https://github.com/dry-rb/dry-configurable/compare/v1.3.0...v1.4.0

## [1.3.0] - 2025-01-04

### Changed

- Set minimum Ruby version to 3.1. (@flash-gordon)

[1.3.0]: https://github.com/dry-rb/dry-configurable/compare/v1.2.0...v1.3.0

## [1.2.0] - 2024-07-03

### Changed

- Allow `Dry::Configurable` mixin to be included multiple times in a class hierarchy. (@timriley in #164)
- Deprecate `Dry::Configurable::AlreadyIncludedError`. (@timriley in #164)

[1.2.0]: https://github.com/dry-rb/dry-configurable/compare/v1.1.0...v1.2.0

## [1.1.0] - 2022-07-16

### Fixed

- Allow nested settings to default to `Undefined`. (@emptyflask in #161)

[1.1.0]: https://github.com/dry-rb/dry-configurable/compare/v1.0.1...v1.1.0

## [1.0.1] - 2022-11-16

### Changed

- Renamed `@config` and `@_settings` internal instance variables to `@__config__` and `@__settings__` in order to avoid clashes with user-defined instance variables. (@timriley in #159)

[1.0.1]: https://github.com/dry-rb/dry-configurable/compare/v1.0.0...v1.0.1

## [1.0.0] - 2022-11-04

### Changed

- Dependency on `dry-core` was updated to ~> 1.0. (@solnic)

[1.0.0]: https://github.com/dry-rb/dry-configurable/compare/v0.16.1...v1.0.0

## [0.16.1] - 2022-10-13

### Changed

- Restored performance of config value reads (direct reader methods as well as aggregate methods like `#values` and `#to_h`) to pre-0.16.0 levels. (@timriley in #149)

[0.16.1]: https://github.com/dry-rb/dry-configurable/compare/v0.16.0...v0.16.1

## [0.16.0] - 2022-10-08

### Added

- Support for custom config classes via `config_class:` option. (@solnic in #136)

  ```ruby
  extend Dry::Configurable(config_class: MyConfig)
  ```

  Your config class should inherit from `Dry::Configurable::Config`.
- Return `Dry::Core::Constants::Undefined` (instead of nil) as the value for non-configured settings via a `default_undefined: true` option. (@timriley in #141)

  ```ruby
  extend Dry::Configurable(default_undefined: true)
  ```

  You must opt into this feature via the `default_undefined: true` option. Non-configured setting values are still `nil` by default.

### Fixed

- Remove exec bit from version.rb. (@Fryguy in #139)

### Changed

- Improve memory usage by separating setting definitions from config values. (@timriley in #138)

  Your usage of dry-configurable may be impacted if you have been accessing objects from `_settings` or the internals of `Dry::Configurable::Config`. `_settings` now returns `Dry::Configurable::Setting` instances, which contain only the details from the setting's definition. Setting _values_ remain in `Dry::Configurable::Config`.
- Use Zeitwerk to speed up load time. (@solnic in #135)

[0.16.0]: https://github.com/dry-rb/dry-configurable/compare/v0.15.0...v0.16.0

## [0.15.0] - 2022-04-21

### Changed

- The `finalize!` method (as class or instance method, depending on whether you extend or include `Dry::Configurable` respectively) now accepts a boolean `freeze_values:` argument, which if true, will recursively freeze all config values in addition to the `config` itself. (@ojab in #105)

  ```ruby
  class MyConfigurable
    include Dry::Configurable

    setting :db, default: "postgre"
  end

  my_obj = MyConfigurable.new
  my_obj.finalize!(freeze_values: true)
  my_obj.config.db << "sql" # Will raise FrozenError
  ```
- `Dry::Configurable::Config#update` will set hashes as values for non-nested settings. (@ojab in #131)

  ```ruby
  class MyConfigurable
    extend Dry::Configurable

    setting :sslcert, constructor: ->(v) { v&.values_at(:pem, :pass)&.join }
  end

  MyConfigurable.config.update(sslcert: {pem: "cert", pass: "qwerty"})
  MyConfigurable.config.sslcert # => "certqwerty"
  ```
- `Dry::Configurable::Config#update` will accept any values implicitly convertible to hash via `#to_hash`. (@timriley in #133)

[0.15.0]: https://github.com/dry-rb/dry-configurable/compare/v0.14.0...v0.15.0

## [0.14.0] - 2022-01-14

### Changed

- Settings defined after an access to `config` will still be made available on that `config`. (@timriley in #130)
- Cloneable settings are cloned immediately upon assignment. (@timriley in #130)
- Changes to config values in parent classes after subclasses have already been created will not be propogated to those subclasses. Subclasses created _after_ config values have been changed in the parent _will_ receive those config values. (@timriley in #130)

[0.14.0]: https://github.com/dry-rb/dry-configurable/compare/v0.13.0...v0.14.0

## [0.13.0] - 2021-09-12

### Added

- Added flags to determine whether to warn on the API usage deprecated in this release (see "Changed" section below). Set these to `false` to suppress the warnings. (@timriley in #124)

  ```ruby
  Dry::Configurable.warn_on_setting_constructor_block false
  Dry::Configurable.warn_on_setting_positional_default false
  ```

### Fixed

- Fixed `ArgumentError` for classes including `Dry::Configurable` whose `initializer` has required kwargs. (@timriley in #113)

### Changed

- Deprecated the setting constructor provided as a block. Provide it via the `constructor:` keyword argument instead. (@waiting-for-dev & @timriley in #111)

  ```ruby
  setting :path, constructor: -> path { Pathname(path) }
  ```
- Deprecated the setting default provided as the second positional argument. Provide it via the `default:` keyword argument instead. (@waiting-for-dev & @timriley in #112 and #121)

  ```ruby
  setting :path, default: "some/default/path"
  ```
- [BREAKING] Removed implicit `to_hash` conversion from `Config`. (@timriley in #114)

[0.13.0]: https://github.com/dry-rb/dry-configurable/compare/v0.12.1...v0.13.0

## [0.12.1] - 2021-02-15

### Added

- Settings may be specified with a `cloneable` option, e.g.

```ruby
setting :component_dirs, Configuration::ComponentDirs.new, cloneable: true
```

This change makes it possible to provide "rich" config values that carry their own
configuration interface.

In the above example, `ComponentDirs` could provide its own API for adding component
dirs and configuring aspects of their behavior at the same time. By being passed to
the setting along with `cloneable: true`, dry-configurable will ensure the setting's
values are cloned along with the setting at all the appropriate times.

A custom cloneable setting value should provide its own `#initialize_copy` (used by
`Object#dup`) with the appropriate logic. (@timriley in #102)

### Fixed

- Only `#initialize` instance method is prepended, leaving the rest of the instance
  methods to be included as normal again. This allows classes including
  `Dry::Configurable` to override instance methods with their own methods as required. (@adam12 in #103)

[0.12.1]: https://github.com/dry-rb/dry-configurable/compare/v0.12.0...v0.12.1

## [0.12.0] - 2020-12-26

### Fixed

- Setting values provided by defaults and/or pre-processor blocks are no longer accidentally memoized across instances of classes including Dry::Configurable. (@timriley & @esparta in #99)

### Changed

- Instance behavior is now prepended, so that if you have your own `initialize`, calling `super` is no longer required. (@zabolotnov87 in #98)
- Switched to equalizer from dry-core. (@solnic)

[0.12.0]: https://github.com/dry-rb/dry-configurable/compare/v0.11.6...v0.12.0

## [0.11.6] - 2020-06-22

### Changed

- A meaningful error is raised when the extension is included more than once. (@landongrindheim in #94)
- Evaluate setting input immediately when input is provided. This allows for earlier feedback from constructors designed to raise errors on invalid input. (@timriley in #95)

[0.11.6]: https://github.com/dry-rb/dry-configurable/compare/v0.11.5...v0.11.6

## [0.11.5] - 2020-03-23

### Fixed

- When settings are copied or cloned, unevaluated values will no longer be copied. This prevents unintended crashes when settings have constructors expecting a certain type of value, but that value is yet to be provided. (@timriley in #87)

### Changed

- A meaningful error is raised when the extension is included more than once. (@landongrindheim in #94)

[0.11.5]: https://github.com/dry-rb/dry-configurable/compare/v0.11.4...v0.11.5

## [0.11.4] - 2020-03-16

### Fixed

- `Config#update` returns `self` again. (@solnic in #92)

### Changed

- `Setting#inspect` no longer uses its value - this could cause crashes when inspecting settings that are yet to have a value applied (e.g. when they have a constructor that expects a value to be present). (@timriley)

[0.11.4]: https://github.com/dry-rb/dry-configurable/compare/v0.11.3...v0.11.4

## [0.11.3] - 2020-02-22

### Fixed

- Retrieving settings by a string name works again. (@waiting-for-dev in #82)

[0.11.3]: https://github.com/dry-rb/dry-configurable/compare/v0.11.2...v0.11.3

## [0.11.2] - 2020-02-20

### Fixed

- Warning about redefined `Setting#value` is gone. (@solnic)

[0.11.2]: https://github.com/dry-rb/dry-configurable/compare/v0.11.1...v0.11.2

## [0.11.1] - 2020-02-18

### Fixed

- You can use `:settings` as a config key again. (@solnic in #80)
- Setting value is lazy-evaluated now, which fixes some cases where a constructor could crash with a `nil` value. (@solnic)

[0.11.1]: https://github.com/dry-rb/dry-configurable/compare/v0.11.0...v0.11.1

## [0.11.0] - 2020-02-15

Complete rewrite of the library while keeping the public API intact. See #78 for a detailed overview.

### Changed

- Accessing config in a parent class no longer prevents you from adding more settings in a child class. (@solnic)
- (internal) New low-level Setting and Config API. (@solnic)
- (internal) `config` objects use method_missing now. (@solnic)

[0.11.0]: https://github.com/dry-rb/dry-configurable/compare/v0.10.0...v0.11.0

## [0.10.0] - 2020-01-31

YANKED because the change also broke inheritance for classes that used `configured` before other classes inherited from them.

### Changed

- Inheriting settings no longer defines the config object. This change fixed a use case where parent class that already used its config would prevent a child class from adding new settings. (@solnic)

[0.10.0]: https://github.com/dry-rb/dry-configurable/compare/v0.9.0...v0.10.0

## [0.9.0] - 2019-11-06

### Fixed

- Support for reserved names in settings. Some Kernel methods (`public_send` and `class` specifically) are not available if you use access settings via method call. Same for methods of the `Config` class. You can still access them with `[]` and `[]=`. Ruby keywords are fully supported. Invalid names containing special symbols (including `!` and `?`) are rejected. Note that these changes don't affect the `reader` option, if you define a setting named `:class` and pass `reader: true` ... well. (@flash-gordon)
- Settings can be redefined in subclasses without a warning about overriding exsting methods. (@flash-gordon)
- Fix warnings about using keyword arguments in 2.7. (@koic)

[0.9.0]: https://github.com/dry-rb/dry-configurable/compare/v0.8.3...v0.9.0

## [0.8.3] - 2019-05-29

### Fixed

- `Configurable#dup` and `Configurable#clone` make a copy of instance-level config so that it doesn't get mutated/shared across instances. (@flash-gordon)

[0.8.3]: https://github.com/dry-rb/dry-configurable/compare/v0.8.2...v0.8.3

## [0.8.2] - 2019-02-25

### Fixed

- Test interface support for modules. (@Neznauy)

[0.8.2]: https://github.com/dry-rb/dry-configurable/compare/v0.8.1...v0.8.2

## [0.8.1] - 2019-02-06

### Fixed

- `.configure` doesn't require a block, this makes the behavior consistent with the previous versions. (@flash-gordon)

[0.8.1]: https://github.com/dry-rb/dry-configurable/compare/v0.8.0...v0.8.1

## [0.8.0] - 2019-02-05

### Added

- Support for instance-level configuration landed. For usage, `include` the module instead of extending. (@flash-gordon)

  ```ruby
  class App
    include Dry::Configurable

    setting :database
  end

  production = App.new
  production.config.database = ENV['DATABASE_URL']
  production.finalize!

  development = App.new
  development.config.database = 'jdbc:sqlite:memory'
  development.finalize!
  ```
- Config values can be set from a hash with `.update`. Nested settings are supported. (@flash-gordon)

  ```ruby
  class App
    extend Dry::Configurable

    setting :db do
      setting :host
      setting :port
    end

    config.update(YAML.load(File.read("config.yml")))
  end
  ```

### Fixed

- A number of bugs related to inheriting settings from parent class were fixed. Ideally, new behavior will be :100: predictable but if you observe any anomaly, please report. (@flash-gordon)

### Changed

- [BREAKING] Minimal supported Ruby version is set to 2.3. (@flash-gordon)

[0.8.0]: https://github.com/dry-rb/dry-configurable/compare/v0.7.0...v0.8.0

## [0.7.0] - 2017-04-25

### Added

- Introduce `Configurable.finalize!` which freezes config and its dependencies. (@qcam)

### Fixed

- Allow for boolean false as default setting value. (@yuszuv)
- Convert nested configs to nested hashes with `Config#to_h`. (@saverio-kantox)
- Disallow modification on frozen config. (@qcam)

[0.7.0]: https://github.com/dry-rb/dry-configurable/releases/tag/v0.7.0
