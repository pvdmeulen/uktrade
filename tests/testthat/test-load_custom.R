# httr2 has built-in mocking support (httr2::local_mocked_responses()) which
# intercepts req_perform() calls for the duration of a test. This means we
# can test the full request/pagination/parsing logic in load_custom()
# without ever hitting the real HMRC API - no fixture files, no internet
# connection required, and the tests are fast and deterministic.
#
# See: https://httr2.r-lib.org/reference/local_mocked_responses.html

test_that("a single-page response is returned as a tibble", {

  httr2::local_mocked_responses(list(
    httr2::response_json(
      status_code = 200,
      body = list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
        value = list(
          list(MonthId = 201901, FlowTypeId = 1, Value = 100),
          list(MonthId = 201902, FlowTypeId = 1, Value = 200)
        )
      )
    )
  ))

  result <- load_custom(
    endpoint = "OTS",
    custom_search = "?$filter=FlowTypeId eq 1"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$MonthId, c(201901, 201902))
})

test_that("output = 'df' returns a plain data.frame", {

  httr2::local_mocked_responses(list(
    httr2::response_json(
      status_code = 200,
      body = list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
        value = list(list(MonthId = 201901, Value = 100))
      )
    )
  ))

  result <- load_custom(endpoint = "OTS", output = "df")

  expect_s3_class(result, "data.frame")
  expect_false(inherits(result, "tbl_df"))
})

test_that("paginated results (via @odata.nextLink) are combined into one result", {

  page_1 <- httr2::response_json(
    status_code = 200,
    body = list(
      `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
      value = list(list(MonthId = 201901, Value = 1)),
      `@odata.nextLink` = "https://api.uktradeinfo.com/OTS?$skip=30000"
    )
  )

  page_2 <- httr2::response_json(
    status_code = 200,
    body = list(
      `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
      value = list(list(MonthId = 201902, Value = 2))
    )
  )

  httr2::local_mocked_responses(list(page_1, page_2))

  result <- load_custom(endpoint = "OTS")

  expect_equal(nrow(result), 2)
  expect_equal(result$MonthId, c(201901, 201902))
})

test_that("a 4xx API response surfaces an informative error", {

  httr2::local_mocked_responses(list(
    httr2::response_json(status_code = 400, body = list(value = list()))
  ))

  expect_error(
    load_custom(endpoint = "OTS", custom_search = "?$filter=bad"),
    "client-side error"
  )
})

test_that("a 5xx API response surfaces an informative error", {

  httr2::local_mocked_responses(list(
    httr2::response_json(status_code = 500, body = list(value = list()))
  ))

  expect_error(
    load_custom(endpoint = "OTS"),
    "server-side error"
  )
})

test_that("an empty (but successful) result set warns", {

  httr2::local_mocked_responses(list(
    httr2::response_json(
      status_code = 200,
      body = list(
        `@odata.context` = "https://api.uktradeinfo.com/$metadata#OTS",
        value = list()
      )
    )
  ))

  expect_warning(
    load_custom(endpoint = "OTS", custom_search = "?$filter=FlowTypeId eq 99"),
    "empty dataset"
  )
})
