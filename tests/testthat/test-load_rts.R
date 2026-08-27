# Unlike load_custom(), load_rts() makes several *different* internal calls
# in sequence (Country and Region lookups up front, then the RTS data itself,
# then - if join_lookup = TRUE - SITC and FlowType lookups to join on). A
# fixed queue of responses (as used in test-load_custom.R) would be brittle
# here, since it'd break if that call order ever changed. Instead we mock
# with a function(req) that inspects the request URL and returns the right
# canned response for whichever endpoint is being hit - see
# https://httr2.r-lib.org/reference/local_mocked_responses.html

test_that("load_rts (join_lookup = TRUE) returns joined, human-readable trade data", {

  mock_rts_api <- function(req) {

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
    } else if (grepl("/Region", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Region",
        value = list(list(
          RegionId = 200, RegionCodeNumeric = "1",
          RegionGroupCodeAlpha = "E", RegionName = "South East",
          RegionGroupName = "England"
        ))
      )
    } else if (grepl("/SITC", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#SITC",
        value = list(list(
          CommoditySitcId = 0, Sitc1Code = "0",
          Sitc1Desc = "Food and live animals",
          Sitc2Code = "00",
          Sitc2Desc = "Live animals other than animals of division 03"
        ))
      )
    } else if (grepl("/FlowType", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#FlowType",
        value = list(list(FlowTypeId = 3, FlowTypeDescription = "Non-EU Imports"))
      )
    } else if (grepl("/RTS", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#RTS",
        value = list(list(
          MonthId = 201901, FlowTypeId = 3, CommoditySitc2Id = 0,
          GovRegionId = 200, CountryId = 1, Value = 500, NetMass = 50
        ))
      )
    } else {
      stop("Unexpected request in mock: ", url)
    }

    httr2::response_json(status_code = 200, body = body)
  }

  httr2::local_mocked_responses(mock_rts_api)

  result <- load_rts(month = c(201901, 201901), sitc = c(0, 0), country = "AU")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$MonthId, 201901)
  expect_equal(result$FlowTypeDescription, "Non-EU Imports")
  expect_equal(result$CountryName, "Australia")
  expect_equal(result$GovRegionGroupName, "England")
  expect_equal(result$Sitc1Desc, "Food and live animals")
})

test_that("load_rts (join_lookup = FALSE) returns raw codes without joining lookups", {

  mock_rts_api <- function(req) {

    url <- req$url

    body <- if (grepl("/Country", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Country",
        value = list(list(CountryId = 1, RegionId = 10, CountryCodeAlpha = "AU"))
      )
    } else if (grepl("/Region", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Region",
        value = list(list(RegionId = 200, RegionGroupName = "England"))
      )
    } else if (grepl("/RTS", url, fixed = TRUE)) {
      list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#RTS",
        value = list(list(
          MonthId = 201901, FlowTypeId = 3, CommoditySitc2Id = 0,
          GovRegionId = 200, CountryId = 1, Value = 500, NetMass = 50
        ))
      )
    } else {
      stop("Unexpected request in mock: ", url)
    }

    httr2::response_json(status_code = 200, body = body)
  }

  httr2::local_mocked_responses(mock_rts_api)

  result <- load_rts(month = c(201901, 201901), join_lookup = FALSE)

  expect_true(all(
    c("MonthId", "FlowTypeId", "CommoditySitc2Id", "GovRegionId",
      "CountryId", "Value") %in% names(result)
  ))
  # No human-readable columns should have been joined on:
  expect_false("FlowTypeDescription" %in% names(result))
  expect_false("CountryName" %in% names(result))
})

test_that("an error from the RTS data endpoint itself is surfaced, even if lookups succeed", {

  mock_rts_api <- function(req) {

    url <- req$url

    if (grepl("/Country", url, fixed = TRUE)) {
      return(httr2::response_json(status_code = 200, body = list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Country",
        value = list(list(CountryId = 1, RegionId = 10))
      )))
    }

    if (grepl("/Region", url, fixed = TRUE)) {
      return(httr2::response_json(status_code = 200, body = list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#Region",
        value = list(list(RegionId = 200))
      )))
    }

    # The RTS data request itself fails server-side:
    httr2::response_json(status_code = 500, body = list(value = list()))
  }

  httr2::local_mocked_responses(mock_rts_api)

  expect_error(
    load_rts(month = c(201901, 201901)),
    "server-side error"
  )
})
