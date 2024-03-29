# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# LOAD_CUSTOM FUNCTION ===============================================================================
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' A function for loading a custom dataset via HMRC's API.
#' @param base_url Base URL for use in API. Defaults to https://api.uktradeinfo.com.
#' @param endpoint Endpoint for use in API. Takes a single character string with no default.
#' @param custom_search Custom query. Takes a single character string with no default.
#' @param skip_interval A non-negative integer value showing the skip interval for paginated results. Defaults to 40,000 rows.
#' @param output A character specifying if a tibble ("tibble") or dataframe ("df") should be returned. Defaults to "tibble".
#' @param request A non-negative integer value to keep track of the starting number of requests made. Defaults to zero. This can be increased in case you are making multiple requests using this function in succession and do not want to exceed the API limit (60 requests per minute).
#' @param timer A non-negative integer value (seconds) to keep track of the time taken so far. Defaults to NULL. This can be increased in case you are making multiple requests using this function in succession and do not want to exceed the API limit (60 requests per minute).
#' @param print_url A logical. Defaults to FALSE. Setting this to TRUE will print the URL(s) used to load data to the console.
#' @param debug A logical. Defaults to FALSE. Setting this to TRUE will print the number of datasets as they are being loaded as well as the elapsed time.
#' @param use_proxy A logical. Defaults to FALSE. Setting this to TRUE will allow the use of a proxy connection using `use_proxy()` from `httr`.
#' @param ... Optional arguments to be passed along to `use_proxy()` when using a proxy connection (by setting use_proxy to TRUE). See the `httr` documentation for more details.
#'
#' @importFrom httr GET
#' @importFrom httr use_proxy
#' @importFrom dplyr bind_rows
#' @importFrom dplyr as_tibble
#'
#' @keywords hmrc api data
#' @rdname load_custom
#' @export
#'
#' @return Returns a dataframe or tibble containing the API response
#' @examples
#' \dontrun{
#' # Obtaining all exports of single malt Scotch whisky and bottled gin between
#' January 2000 and December 2020 via the OTS endpoint:
#'
#' custom_search <- paste0(
#'   "?$filter= (FlowTypeId eq 2 or FlowTypeId eq 4)",
#'   " and (CommodityId eq 22083030 or CommodityId eq 22085011)",
#'   " and (MonthId ge 201001 and MonthId le 202012)"
#'   )
#'
#' data <- load_custom(endpoint = "OTS", custom_search = custom_search)
#'
#' # Note that there are more than 30,000 rows returned:
#'
#' nrow(data)
#'
#' }

load_custom <- function(base_url = "https://api.uktradeinfo.com",
                        endpoint,
                        custom_search = "",
                        request = 1,
                        skip_interval = 4e4,
                        timer = NULL,
                        output = "tibble",
                        print_url = FALSE,
                        debug = FALSE,
                        use_proxy = FALSE,
                        ...
){

  check_internet()

  done <- FALSE
  data <- list()

  request <- request
  skip <- 0
  page <- 1

  # Create timer reference point:
  timer <- if(is.null(timer)){ proc.time() } else { timer }

  # URL print message if set to TRUE:
  if(print_url == TRUE){message("Loading data via the following URL(s):")}

  # While not all results are loaded:
  while(done == FALSE){

    # Debug message:
    if(debug == TRUE){print(paste0("Loading dataset ", request,
                                   " with an elapsed time of ",
                                   round(
                                     proc.time()[[3]] - timer[[3]], digits = 3
                                   ), " seconds"))}

    # Construct skip suffix:
    skip_suffix <- if(skip == 0) { NULL } else {
      paste0("&$skip=", format(skip, scientific = FALSE)) }

    # Construct URL:
    url <- paste0(base_url, "/", endpoint, custom_search, skip_suffix)

    # Print URL if set to TRUE:
    if(print_url == TRUE){message("URL ", request, ": ", url)}

    # Get API response:

    if(use_proxy == TRUE){

      response <- httr::GET(utils::URLencode(url), httr::use_proxy(...))

    } else {

      response <- httr::GET(utils::URLencode(url))

    }

    # Check status:
    check_status(response)

    # Add request:
    request <- request + 1

    # Get elapsed time:
    elapsed_time <- proc.time()[[3]] - timer[[3]]

    # Check if we've reached API limit (60/min):
    if(request %% 59 == 0 & request/elapsed_time > 58/60){

      # Rest for 5 seconds:
      message(paste0("Nearly reached query limit (60/min). Pausing for ", 30,
                     " seconds..."))

      Sys.sleep(30)

      message(paste0("Resuming download..."))

    }

    content <- jsonlite::fromJSON(rawToChar(response$content))

    # Put response into data list:

    data[[page]] <- content$value

    # If response indicates there's a next page:
    if(length(names(content)) < 3) { done <- TRUE } else {

      skip <- skip + skip_interval

      page <- page + 1

    }

  } # End of while done == FALSE

  # Reset timer? Is this needed...?
  timer <- proc.time()

  # Return data:

  data <- if(output == "df") {

    dplyr::bind_rows(data)

  } else if(output == "tibble") {

    dplyr::as_tibble(dplyr::bind_rows(data))

  }

  return(data)

} # End of function
