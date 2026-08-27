# check_status() takes an httr2 response object. httr2::response() lets us
# build one of those by hand for testing, so these tests need no network
# access and no mocking framework.

test_that("a 4xx response raises a client-side error", {
  resp <- httr2::response(
    status_code = 404,
    url = "https://api.uktradeinfo.com/OTS",
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"value": []}')
  )

  expect_error(check_status(resp), "client-side error")
})

test_that("a 5xx response raises a server-side error", {
  resp <- httr2::response(
    status_code = 503,
    url = "https://api.uktradeinfo.com/OTS",
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"value": []}')
  )

  expect_error(check_status(resp), "server-side error")
})

test_that("a successful but empty response warns instead of erroring", {
  resp <- httr2::response(
    status_code = 200,
    url = "https://api.uktradeinfo.com/OTS",
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"value": []}')
  )

  expect_warning(check_status(resp), "empty dataset")
})

test_that("a successful, non-empty response is neither an error nor a warning", {
  resp <- httr2::response(
    status_code = 200,
    url = "https://api.uktradeinfo.com/OTS",
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"value": [{"MonthId": 201901, "Value": 100}]}')
  )

  expect_no_condition(check_status(resp))
})
