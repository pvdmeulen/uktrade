# BASIC CHECK FOR INTERNET CONNECTION =============================================================

#' A function to check for internet connection. Used within `load_*()` functions.
#' @importFrom curl has_internet
#' @importFrom httr status_code

check_internet <- function(){
  if(curl::has_internet() == FALSE){stop("No internet connection found.")}
}
