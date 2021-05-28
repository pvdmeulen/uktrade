# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# LOAD_CUSTOM FUNCTION ===============================================================================
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# A function for loading a custom dataset via HMRC's API.

#' @param base_url Base URL for use in API. Defaults to https://api.uktradeinfo.com.
#' @param endpoint Endpoint for use in API. Takes a single character string with no default.
#' @param custom_search Custom query. Takes a single character string with no default.
#' @param request A non-negative integer value to keep track of the starting number of requests made. Defaults to zero. This can be increased in case you are making multiple requests using this function in succession and do not want to exceed the API limit (60 requests per minute).
#' @param skip_interval A non-negative integer value showing the skip interval for paginated results. Defaults to 30,000 rows.
#'
#' @importFrom httr GET
#' @importFrom curl has_internet
#' @importFrom dplyr bind_rows
#'
#' @keywords hmrc api data
#' @rdname loadcustom
#' @export
#'
#' @return Returns a dataframe containing the API response
#' @examples
#' \dontrun{
#' # Obtaining all exports of single malt Scotch whisky and bottled gin between January 2000 and December 2020 via the OTS endpoint:
#' data <- load_custom(endpoint = "OTS", custom_search = "?$filter= (FlowTypeId eq 2 or FlowTypeId eq 4) and (CommodityId eq 22083030 or CommodityId eq 22085011) and (MonthId ge 201001 and MonthId le 202012)")
#'
#' # Note that there are more than 30,000 rows returned:
#' nrow(data)
#' }


load_custom <- function(base_url = "https://api.uktradeinfo.com", endpoint, custom_search, request = 0, skip_interval = 30000){

  done <- FALSE
  data <- list()

  request <- request
  skip <- 0
  page <- 1

  while(done == FALSE){

    # Construct skip suffix:
    skip_suffix <- if(skip == 0) { NULL } else { paste0("&$skip=", skip) }

    # Construct URL:
    url <- paste0(base_url, "/", endpoint, custom_search, skip_suffix)

    # Start timer:
    timer <- proc.time()

    # Get API response:
    response <- httr::GET(URLencode(url))

    # Check status:
    #check_status(response)

    # Add request:
    request <- request + 1

    # Get elapsed time:
    elapsed_time <- proc.time()[[3]] - timer[[3]]

    # Check if we've reached API limit (60/min):
    if(request > 59 & elapsed_time < 60){

      # Rest for 5 seconds:
      message(paste0("Reached query limit (60/min). Pausing for ", 60-elapsed_time+1, " seconds."))

      Sys.sleep(60-elapsed_time+1)

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

  # Return data:

  return(dplyr::bind_rows(data))

} # End of function
