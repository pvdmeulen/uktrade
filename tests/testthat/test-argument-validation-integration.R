# These tests deliberately do NOT set up httr2::local_mocked_responses().
# That's intentional: it means these functions must reject bad arguments
# before attempting any HTTP request. If the validation calls were ever
# accidentally moved to after the API calls (or removed), these tests would
# instead try to hit the real HMRC API and fail/hang rather than erroring
# cleanly - which is exactly the regression this guards against.

test_that("load_ots() validates arguments before making any API calls", {
  expect_error(load_ots(output = "not-a-real-output"), "output")
  expect_error(load_ots(flow = 99), "flow")
  expect_error(load_ots(country = "AUS"), "country")
  expect_error(load_ots(commodity = c(0, 22083030)), "not both")
  expect_error(load_ots(sitc = 12345), "character")
})

test_that("load_rts() validates arguments before making any API calls", {
  expect_error(load_rts(output = "not-a-real-output"), "output")
  expect_error(load_rts(uk_country = "Cornwall"), "uk_country")
  # RTS data only ever has flow codes 3 and 4 - see load_rts()'s `flow` docs:
  expect_error(load_rts(flow = 1), "flow")
  expect_error(load_rts(flow = 2), "flow")
})

test_that("load_custom() validates arguments before making any API calls", {
  expect_error(
    load_custom(endpoint = "OTS", output = "not-a-real-output"),
    "output"
  )
})
