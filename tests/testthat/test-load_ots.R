# load_ots() makes even more internal calls than load_rts(): Country, OTS
# (the main data), Commodity, SITC, FlowType, and Port lookups - plus an
# inline (non-API) suppression-code lookup. As with test-load_rts.R, we mock
# with a function(req) that dispatches on the request URL rather than a
# fixed queue of responses, since the exact call order is an implementation
# detail we don't want these tests coupled to.

test_that("load_ots (join_lookup = TRUE) returns joined, human-readable trade data", {

  mock_ots_api <- function(req) {

    url <- req$url

    body <- if (grepl("/Country", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Country",
        value = list(list(
          CountryId = 1, RegionId = 10, CountryCodeNumeric = "036",
          CountryCodeAlpha = "AU", CountryName = "Australia",
          Area1a = "Asia and Oceania"
        ))
      )
    } else if (grepl("/Commodity", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Commodity",
        value = list(list(
          CommodityId = 22083030,
          Hs2Code = "22", Hs2Desc = "Beverages, spirits and vinegar",
          Cn8Code = "22083030", Cn8Desc = "Single malt Scotch whisky"
        ))
      )
    } else if (grepl("/SITC", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#SITC",
        value = list(list(
          CommoditySitcId = "11212", Sitc1Code = "1",
          Sitc1Desc = "Beverages and tobacco"
        ))
      )
    } else if (grepl("/FlowType", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#FlowType",
        value = list(list(FlowTypeId = 4, FlowTypeDescription = "Non-EU Exports"))
      )
    } else if (grepl("/Port", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Port",
        value = list(list(
          PortId = 1, PortCodeNumeric = "001",
          PortCodeAlpha = "DVR", PortName = "Dover"
        ))
      )
    } else if (grepl("/OTS", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
        value = list(list(
          MonthId = 201901, FlowTypeId = 4, CommodityId = 22083030,
          CommoditySitcId = "11212", CountryId = 1, PortId = 1,
          SuppressionIndex = 1, Value = 1000, NetMass = 50, SuppUnit = "kg"
        ))
      )
    } else {
      stop("Unexpected request in mock: ", url)
    }

    httr2::response_json(status_code = 200, body = body)
  }

  httr2::local_mocked_responses(mock_ots_api)

  result <- load_ots(
    month = c(201901, 201912),
    commodity = 22083030,
    country = "AU"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$MonthId, 201901)
  expect_equal(result$FlowTypeDescription, "Non-EU Exports")
  expect_equal(result$CountryName, "Australia")
  expect_equal(result$Cn8Desc, "Single malt Scotch whisky")
  expect_equal(result$PortName, "Dover")
  expect_equal(
    result$SuppressionDesc,
    "Complete suppression, where no information is published."
  )
})

test_that("load_ots (join_lookup = FALSE) returns raw codes without joining lookups", {

  mock_ots_api <- function(req) {

    url <- req$url

    body <- if (grepl("/Country", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Country",
        value = list(list(CountryId = 1, RegionId = 10, CountryCodeAlpha = "AU"))
      )
    } else if (grepl("/OTS", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
        value = list(list(
          MonthId = 201901, FlowTypeId = 4, CommodityId = 22083030,
          CommoditySitcId = "11212", CountryId = 1, PortId = 1,
          SuppressionIndex = 1, Value = 1000, NetMass = 50, SuppUnit = "kg"
        ))
      )
    } else {
      stop("Unexpected request in mock: ", url)
    }

    httr2::response_json(status_code = 200, body = body)
  }

  httr2::local_mocked_responses(mock_ots_api)

  result <- load_ots(
    month = c(201901, 201912),
    commodity = 22083030,
    join_lookup = FALSE
  )

  expect_true(all(
    c("MonthId", "FlowTypeId", "CommodityId", "CommoditySitcId",
      "CountryId", "PortId", "SuppressionIndex", "Value") %in% names(result)
  ))
  # No human-readable columns should have been joined on:
  expect_false("FlowTypeDescription" %in% names(result))
  expect_false("CountryName" %in% names(result))
  expect_false("Cn8Desc" %in% names(result))
})

test_that("an empty OTS result is returned as-is rather than erroring on the join", {

  # Regression test mirroring the equivalent one in test-load_rts.R: an
  # empty API result collapses to a 0-row/0-column tibble via bind_rows(),
  # which previously caused the first left_join() (by "FlowTypeId") to fail.

  mock_ots_api <- function(req) {

    url <- req$url

    body <- if (grepl("/Country", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Country",
        value = list(list(CountryId = 1, RegionId = 10))
      )
    } else if (grepl("/OTS", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
        value = list()
      )
    } else {
      stop("Unexpected request in mock: ", url)
    }

    httr2::response_json(status_code = 200, body = body)
  }

  httr2::local_mocked_responses(mock_ots_api)

  expect_warning(
    result <- load_ots(month = c(201901, 201912)),
    "empty dataset"
  )

  expect_equal(nrow(result), 0)
})

test_that("an error from the OTS data endpoint itself is surfaced, even if the country lookup succeeds", {

  mock_ots_api <- function(req) {

    url <- req$url

    if (grepl("/Country", url, fixed = TRUE)) {
      return(httr2::response_json(status_code = 200, body = list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Country",
        value = list(list(CountryId = 1, RegionId = 10))
      )))
    }

    # The OTS data request itself fails server-side:
    httr2::response_json(status_code = 500, body = list(value = list()))
  }

  httr2::local_mocked_responses(mock_ots_api)

  expect_error(
    load_ots(month = c(201901, 201912)),
    "server-side error"
  )
})

test_that("a message is shown when loading all commodities (no commodity/sitc filter)", {

  mock_ots_api <- function(req) {

    url <- req$url

    body <- if (grepl("/Country", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Country",
        value = list(list(CountryId = 1, RegionId = 10))
      )
    } else if (grepl("/Commodity", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Commodity",
        value = list(list(CommodityId = 1))
      )
    } else if (grepl("/SITC", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#SITC",
        value = list(list(CommoditySitcId = "1"))
      )
    } else if (grepl("/FlowType", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#FlowType",
        value = list(list(FlowTypeId = 4, FlowTypeDescription = "Non-EU Exports"))
      )
    } else if (grepl("/Port", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Port",
        value = list(list(PortId = 1))
      )
    } else if (grepl("/OTS", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
        value = list(list(
          MonthId = 201901, FlowTypeId = 4, CommodityId = 1,
          CommoditySitcId = "1", CountryId = 1, PortId = 1,
          SuppressionIndex = 1, Value = 1, NetMass = 1, SuppUnit = "kg"
        ))
      )
    } else {
      stop("Unexpected request in mock: ", url)
    }

    httr2::response_json(status_code = 200, body = body)
  }

  httr2::local_mocked_responses(mock_ots_api)

  expect_message(
    load_ots(month = c(201901, 201912)),
    "Loading detailed trade data for all commodities"
  )
})
