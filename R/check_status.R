# BASIC CHECK FOR API RESPONSE STATUS =============================================================

#' A function to check the API's response. Used within `load_*()` functions.
#' @importFrom httr status_code

check_status <- function(res){

  if(httr::status_code(res) > 399 & httr::status_code(res) < 500){ stop(paste0("The API returned an error with status code ", httr::status_code(res), " (a client-side error). Are you sure you specified the request correctly?")) }

  if(httr::status_code(res) > 499){ stop(paste0("The API returned an error with status code ", httr::status_code(res), " (a server-side error). Please try again later.")) }

}
