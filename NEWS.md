# uktrade 0.8.0

Switched to `httr2` under the hood (bye `httr`/`jsonlite`), added a proper test suite, and fixed a couple of real bugs along the way.

**Breaking-ish:**

* `use_proxy = TRUE` now uses `httr2::req_proxy()` instead of `httr::use_proxy()`. Same idea, but the `...` args should match `req_proxy()`'s params (`url`, `port`, `username`, `password`, `auth`).
* `load_ots()`, `load_rts()`, and `load_custom()` now validate their arguments up front and error on bad input instead of failing silently or confusingly later on (bad `output`, `flow`, `month`, `country`, `region`, `uk_country`, `suppression`, or any of the TRUE/FALSE args).

**Fixes:**

* Empty results no longer blow up with a `left_join()` error - `load_ots()`/`load_rts()` now just hand back the empty result.
* Turns out RTS data only ever has flow codes 3 and 4, and despite the "Non-EU" label, those actually cover *all* trade, not just non-EU. `load_rts()` now reflects that (docs + validation), instead of quietly returning nothing for flow 1/2.

**Also:**

* Rate limiting and retries are now handled automatically by `httr2` instead of manual `Sys.sleep()` bookkeeping.
* Added tests (`testthat` + `httr2`'s mocking, no real API calls needed) and a coverage badge/workflow.

# uktrade 0.7.2

* See GitHub releases for changes prior to 0.8.0.
