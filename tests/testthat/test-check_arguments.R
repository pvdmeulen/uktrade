# These are all pure, network-free validation functions, so tests run
# instantly. Each one is checked for: NULL is allowed (no-op), a valid value
# is a no-op, and an invalid value raises an informative error.

test_that("check_logical_arg accepts NULL, TRUE, and FALSE", {
  expect_no_condition(check_logical_arg(NULL, "print_url"))
  expect_no_condition(check_logical_arg(TRUE, "print_url"))
  expect_no_condition(check_logical_arg(FALSE, "print_url"))
})

test_that("check_logical_arg rejects non-logical, NA, or multi-length values", {
  expect_error(check_logical_arg("TRUE", "print_url"), "print_url")
  expect_error(check_logical_arg(1, "print_url"), "print_url")
  expect_error(check_logical_arg(NA, "print_url"), "print_url")
  expect_error(check_logical_arg(c(TRUE, FALSE), "print_url"), "print_url")
})

test_that("check_output_arg accepts NULL, 'tibble', and 'df'", {
  expect_no_condition(check_output_arg(NULL))
  expect_no_condition(check_output_arg("tibble"))
  expect_no_condition(check_output_arg("df"))
})

test_that("check_output_arg rejects anything else", {
  expect_error(check_output_arg("list"), "output")
  expect_error(check_output_arg(c("tibble", "df")), "output")
})

test_that("check_flow_arg accepts NULL and values 1-4", {
  expect_no_condition(check_flow_arg(NULL))
  expect_no_condition(check_flow_arg(1))
  expect_no_condition(check_flow_arg(c(1, 2, 3, 4)))
})

test_that("check_flow_arg rejects out-of-range or non-numeric values", {
  expect_error(check_flow_arg(5), "flow")
  expect_error(check_flow_arg(0), "flow")
  expect_error(check_flow_arg("1"), "flow")
})

test_that("check_flow_arg respects a restricted `valid` set (as used by load_rts())", {
  expect_no_condition(check_flow_arg(3, valid = 3:4))
  expect_no_condition(check_flow_arg(c(3, 4), valid = 3:4))
  expect_error(check_flow_arg(1, valid = 3:4), "flow")
  expect_error(check_flow_arg(2, valid = 3:4), "flow")
})

test_that("check_month_arg accepts NULL, a single value, and an ordered pair", {
  expect_no_condition(check_month_arg(NULL))
  expect_no_condition(check_month_arg(201901))
  expect_no_condition(check_month_arg(c(201901, 201912)))
})

test_that("check_month_arg rejects non-numeric, >2 values, or a reversed range", {
  expect_error(check_month_arg("201901"), "month")
  expect_error(check_month_arg(c(201901, 201902, 201903)), "month")
  expect_error(check_month_arg(c(201912, 201901)), "minimum")
})

test_that("check_country_arg accepts NULL and 2-letter codes", {
  expect_no_condition(check_country_arg(NULL))
  expect_no_condition(check_country_arg("AU"))
  expect_no_condition(check_country_arg(c("AU", "US")))
})

test_that("check_country_arg rejects codes that aren't 2 letters", {
  expect_error(check_country_arg("AUS"), "country")
  expect_error(check_country_arg("1U"), "country")
})

test_that("check_region_arg accepts NULL and documented region names", {
  expect_no_condition(check_region_arg(NULL))
  expect_no_condition(check_region_arg("Asia and Oceania"))
  expect_no_condition(check_region_arg(c("Asia and Oceania", "North America")))
})

test_that("check_region_arg rejects undocumented region names", {
  expect_error(check_region_arg("Antarctica"), "region")
})

test_that("check_uk_country_arg accepts NULL and documented UK country names", {
  expect_no_condition(check_uk_country_arg(NULL))
  expect_no_condition(check_uk_country_arg("England"))
  expect_no_condition(check_uk_country_arg(c("England", "Wales")))
})

test_that("check_uk_country_arg rejects undocumented UK country names", {
  expect_error(check_uk_country_arg("Cornwall"), "uk_country")
})

test_that("check_suppression_arg accepts NULL and values 1-5", {
  expect_no_condition(check_suppression_arg(NULL))
  expect_no_condition(check_suppression_arg(1))
  expect_no_condition(check_suppression_arg(c(1, 2, 3, 4, 5)))
})

test_that("check_suppression_arg rejects out-of-range or non-numeric values", {
  expect_error(check_suppression_arg(6), "suppression")
  expect_error(check_suppression_arg(0), "suppression")
  expect_error(check_suppression_arg("1"), "suppression")
})
