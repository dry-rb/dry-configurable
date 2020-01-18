## 0.9.0 2019-11-06


### Fixed

- Support for reserved names in settings. Some Kernel methods (`public_send` and `class` specifically) are not available if you use access settings via method call. Same for methods of the `Config` class. You can still access them with `[]` and `[]=`. Ruby keywords are fully supported. Invalid names containing special symbols (including `!` and `?`) are rejected. Note that these changes don't affect the `reader` option, if you define a setting named `:class` and pass `reader: true` ... well ... (flash-gordon)
- Settings can be redefined in subclasses without a warning about overriding exsting methods (flash-gordon)
- Fix warnings about using keyword arguments in 2.7 (koic)

[Compare v0.8.3...v0.9.0](https://github.com/dry-rb/dry-configurable/compare/v0.8.3...v0.9.0)

## 0.8.3 2019-05-29


### Fixed

- `Configurable#dup` and `Configurable#clone` make a copy of instance-level config so that it doesn't get mutated/shared across instances (flash-gordon)

[Compare v0.8.2...v0.8.3](https://github.com/dry-rb/dry-configurable/compare/v0.8.2...v0.8.3)

## 0.8.2 2019-02-25


### Fixed

- Test interface support for modules ([Neznauy](https://github.com/Neznauy))

[Compare v0.8.1...v0.8.2](https://github.com/dry-rb/dry-configurable/compare/v0.8.1...v0.8.2)

## 0.8.1 2019-02-06


### Fixed

- `.configure` doesn't require a block, this makes the behavior consistent with the previous versions ([flash-gordon](https://github.com/flash-gordon))

[Compare v0.8.0...v0.8.1](https://github.com/dry-rb/dry-configurable/compare/v0.8.0...v0.8.1)

## 0.8.0 2019-02-05


### Added

- Support for instance-level configuration landed. For usage, `include` the module instead of extending ([flash-gordon](https://github.com/flash-gordon))

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
- Config values can be set from a hash with `.update`. Nested settings are supported ([flash-gordon](https://github.com/flash-gordon))

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

- A number of bugs related to inheriting settings from parent class were fixed. Ideally, new behavior will be :100: predictable but if you observe any anomaly, please report ([flash-gordon](https://github.com/flash-gordon))

### Changed

- [BREAKING] Minimal supported Ruby version is set to 2.3 ([flash-gordon](https://github.com/flash-gordon))
[Compare v0.7.0...v0.8.0](https://github.com/dry-rb/dry-configurable/compare/v0.7.0...v0.8.0)

## 0.7.0 2017-04-25


### Added

- Introduce `Configurable.finalize!` which freezes config and its dependencies ([qcam](https://github.com/qcam))

### Fixed

- Allow for boolean false as default setting value ([yuszuv](https://github.com/yuszuv))
- Convert nested configs to nested hashes with `Config#to_h` ([saverio-kantox](https://github.com/saverio-kantox))
- Disallow modification on frozen config ([qcam](https://github.com/qcam))
