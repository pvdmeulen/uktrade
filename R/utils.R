# BASIC CHECKS ====================================================================================

#' @importFrom attempt stop_if_not
#' @importFrom curl has_internet

check_internet <- function(){
  stop_if_not(.x = has_internet(), msg = "No internet connection found.")
}

#' @importFrom httr status_code

check_status <- function(res){
  stop_if(.x = status_code(res), 
          .p = ~ .x > 399 & .x < 500,
           msg = paste0("The API returned an error with status code ", status_code, " (a client-side error). Are you sure you specified the request correctly?")
  )
  
  stop_if(.x = status_code(res), 
          .p = ~ .x > 499,
          msg = paste0("The API returned an error with status code ", status_code, " (a server-side error). Please try again later.")
  )
  
}

# Create base URL:

base_url <- "https://api.uktradeinfo.com"