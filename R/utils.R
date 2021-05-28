# BASIC CHECKS ====================================================================================

#' @importFrom attempt stop_if_not
#' @importFrom curl has_internet
#' @importFrom httr status_code

check_internet <- function(){
  attempt::stop_if_not(.x = curl::has_internet(), msg = "No internet connection found.")
}

#' @importFrom httr status_code

check_status <- function(res){
  attempt::stop_if(.x = httr::status_code(res),
                   .p = ~ .x > 399 & .x < 500,
                   msg = paste0("The API returned an error with status code ", status_code, " (a client-side error). Are you sure you specified the request correctly?")
                   )

  attempt::stop_if(.x = httr::status_code(res),
                   .p = ~ .x > 499,
                   msg = paste0("The API returned an error with status code ", status_code, " (a server-side error). Please try again later.")
                   )
}
