## Unreleased

## Changed

* [BREAKING] Minimal supported Ruby version is set to 2.3 (flash-gordon)

[Compare v0.7.0...HEAD](https://github.com/dry-rb/dry-configurable/compare/v0.7.0...HEAD)

## 0.7.0

## Added

* Introduce `Configurable.finalize!` which freezes config and its dependencies ([qcam](https://github.com/qcam))

## Fixed

* Allow for boolean false as default setting value ([yuszuv](https://github.com/yuszuv))
* Convert nested configs to nested hashes with `Config#to_h` ([saverio-kantox](https://github.com/saverio-kantox))
* Disallow modification on frozen config ([qcam](https://github.com/qcam))

[Compare v0.6.2...v0.7.0](https://github.com/dry-rb/dry-configurable/compare/v0.6.2...v0.7.0)
