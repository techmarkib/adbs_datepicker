## 0.1.0

* Initial release.

### Changed

* **Update support:** existing values are now restored properly.
  * `initialAdDate` is honoured by BS display formats (previously ignored —
    the picker selected today instead of the stored value).
  * Compact BS input (e.g. `2083-6-14`) is normalized, so the stored day is
    actually selected.
  * The picker re-syncs when rebuilt with different initial values
    (`didUpdateWidget`), so edit forms can load another record into a
    mounted picker.
  * New `initialBsEndDate`, `initialAdEndDate`, `initialTime` and
    `initialEndTime` parameters to restore saved ranges and times.
* Removed the unused `SelectionType` API from `NepaliDateValue`.
