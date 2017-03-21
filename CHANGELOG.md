## Unreleased

## Added

* Introduce `Configurable.finalize!` which freezes config and its dependencies ([qcam](https://github.com/qcam))

## Fixed

* Allow for boolean false as default setting value ([yuszuv](https://github.com/yuszuv))
* Convert nested configs to nested hashes with `Config#to_h` ([saverio-kantox](https://github.com/saverio-kantox))
* Disallow modification on frozen config ([qcam](https://github.com/qcam))

[Compare v0.6.2...HEAD](https://github.com/dry-rb/dry-configurable/compare/v0.6.2...HEAD)
