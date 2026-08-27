# create_filter() is pure string-building logic (no HTTP calls), so these
# run instantly and don't need any mocking - they're the cheapest possible
# tests to have covering the trickiest part of the package: translating
# HS/CN/SITC code lengths into the correct OData range filters.

test_that("simple id fields get an 'eq'/'or' filter", {
  result <- create_filter(list(FlowTypeId = c(1, 2)))

  expect_equal(result$FlowTypeId, "(FlowTypeId eq 1 or FlowTypeId eq 2)")
})

test_that("MonthId gets a 'ge'/'le' range filter", {
  result <- create_filter(list(MonthId = c(201901, 201912)))

  expect_equal(result$MonthId, "(MonthId ge 201901 and MonthId le 201912)")
})

test_that("full CN8 commodity codes get a simple 'eq' filter", {
  result <- create_filter(list(CommodityId = 22083030))

  expect_match(result$CommodityId, "CommodityId eq 22083030", fixed = TRUE)
})

test_that("multiple CN8 commodity codes are combined with 'or'", {
  result <- create_filter(list(CommodityId = c(22083030, 22085011)))

  expect_match(result$CommodityId, "CommodityId eq 22083030", fixed = TRUE)
  expect_match(result$CommodityId, "CommodityId eq 22085011", fixed = TRUE)
  expect_match(result$CommodityId, " or ", fixed = TRUE)
})

test_that("full (2-digit) HS2 commodity codes get a range filter plus BTTA code", {
  result <- create_filter(list(CommodityId = "22"))

  expect_match(result$CommodityId, "CommodityId ge 22000000", fixed = TRUE)
  expect_match(result$CommodityId, "CommodityId le 22999999", fixed = TRUE)
  # Below Threshold Trade Allocation estimate code:
  expect_match(result$CommodityId, "CommodityId eq 229999999", fixed = TRUE)
})

test_that("partial (1-digit) HS2 commodity codes get a padded range filter plus BTTA code", {
  result <- create_filter(list(CommodityId = "3"))

  expect_match(result$CommodityId, "CommodityId ge 03000000", fixed = TRUE)
  expect_match(result$CommodityId, "CommodityId le 03999999", fixed = TRUE)
  expect_match(result$CommodityId, "CommodityId eq 039999999", fixed = TRUE)
})

test_that("HS4/HS6 commodity codes get a range filter without a BTTA code", {
  result <- create_filter(list(CommodityId = "2208"))

  expect_match(result$CommodityId, "CommodityId ge 22080000", fixed = TRUE)
  expect_match(result$CommodityId, "CommodityId le 22089999", fixed = TRUE)
  expect_false(grepl("9999999", result$CommodityId, fixed = TRUE))
})

test_that("full (2-digit) SITC codes get a range filter plus BTTA code", {
  result <- create_filter(list(CommoditySitcId = "11"))

  expect_match(result$CommoditySitcId, "CommoditySitcId ge 11000", fixed = TRUE)
  expect_match(result$CommoditySitcId, "CommoditySitcId le 11999", fixed = TRUE)
  expect_match(result$CommoditySitcId, "CommoditySitcId eq 1199999", fixed = TRUE)
})

test_that("SITC5 codes get a simple 'eq' filter", {
  result <- create_filter(list(CommoditySitcId = "11241"))

  expect_match(result$CommoditySitcId, "CommoditySitcId eq 11241", fixed = TRUE)
})
