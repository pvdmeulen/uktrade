# uktrade 0.8.0

## Bug fixes

* `load_ots()` and `load_rts()` no longer error when a filter matches zero
  rows. Previously, an empty API result collapsed to a 0-row/0-column
  tibble, and the subsequent `left_join()` onto lookup tables (starting
  with `FlowTypeId`) failed with `Join columns in \`x\` must be present in
  the data`. Both functions now return the empty result as-is (with a
  warning already raised by `check_status()`) instead of attempting the
  joins.

* `load_rts()`'s `flow` argument previously documented (and allowed) all
  four OTS-style flow codes (1: EU imports, 2: EU exports, 3: non-EU
  imports, 4: non-EU exports). In practice, RTS data is only ever
  populated for codes 3 and 4 - `flow = 1` or `flow = 2` would silently
  return zero rows. `load_rts()` now validates `flow` against `3:4` and
  errors informatively if 1 or 2 is passed, and the documentation has been
  corrected. Note also that despite the `FlowType` lookup's "Non-EU
  Imports"/"Non-EU Exports" labels, RTS's codes 3 and 4 actually cover
  *all* imports/exports (EU and non-EU combined) - the label is
  misleading for RTS specifically (it's accurate for `load_ots()`'s OTS
  data). Thanks to @pvdmeulen for tracking this down against the live API.

## Breaking changes

* The package now uses `httr2` internally instead of `httr`, which is now
  end-of-life for new feature development. This is mostly an internal
  change, but it does affect the proxy-related arguments:

  - `use_proxy = TRUE` now builds a proxy connection with
    `httr2::req_proxy()` instead of `httr::use_proxy()`. Arguments passed
    via `...` should match `req_proxy()`'s parameters (`url`, `port`,
    `username`, `password`, `auth`) rather than `use_proxy()`'s. For the
    common case (a proxy URL and port, no auth) the two are compatible,
    but authenticated proxies may need updating.

* `load_ots()`, `load_rts()`, and `load_custom()` now validate their
  arguments *before* making any API calls, and will error informatively on
  values that previously either failed confusingly deep in the call stack,
  or - in the case of an invalid `output` value - silently returned `NULL`.
  If your code was accidentally relying on one of these being silently
  ignored (e.g. a typo'd `region`, or a `flow` value outside 1-4), it will
  now raise an error instead. See "New features" below for the full list
  of arguments now checked.

## New features

* The 60 requests/minute rate limit is now enforced automatically via
  `httr2::req_throttle()`, shared across every call made in an R session
  (including the internal lookup calls `load_ots()`/`load_rts()` make) via
  a common throttling "realm". This replaces the old manual request-count
  and `Sys.sleep()` bookkeeping, so it should be both more accurate and
  more resilient to interleaved calls.

* Requests are now automatically retried (up to 3 attempts) on transient
  server-side errors (HTTP 429, 500, 502, 503, 504) via
  `httr2::req_retry()`.

* `load_ots()`, `load_rts()`, and `load_custom()` now validate their
  arguments up front:

  - `output` must be `"tibble"` or `"df"`
  - `flow` must be one or more of `1`, `2`, `3`, `4` (`load_ots()`), or
    `3`, `4` only (`load_rts()` - see "Bug fixes" above)
  - `month` must be numeric, at most 2 values, and (if 2 values) in
    ascending order
  - `country` must be one or more 2-letter codes
  - `region` (and, for `load_rts()`, `uk_country`) must be one of the
    documented values
  - `suppression` (for `load_ots()`) must be one or more integers 1-5
  - `join_lookup`, `print_url`, `use_proxy` (and, for `load_custom()`,
    `debug`) must each be a single `TRUE`/`FALSE`

## Testing

* Added a `testthat` suite covering `create_filter()`, `check_status()`, 
  `load_custom()`, `load_ots()`, `load_rts()`, and the argument validation
  helpers. Tests use `httr2::local_mocked_responses()` to simulate the HMRC API,
  so the suite runs offline and doesn't count against the real API's rate limit.

* Added a `test-coverage.yaml` GitHub Actions workflow (using `covr`) that
  uploads coverage to Codecov on every push/PR, and a corresponding badge
  in the README. To enable this, add a `CODECOV_TOKEN` repository secret
  (from https://app.codecov.io) in the GitHub repo settings.

## Internal

* `jsonlite` is no longer a direct dependency; response parsing goes
  through `httr2::resp_body_json()`.
* Dead code around a `skip_interval` "max page size" warning (which could
  never actually trigger) was removed from `load_custom()`.

# uktrade 0.7.2

* See GitHub releases for changes prior to 0.8.0.
