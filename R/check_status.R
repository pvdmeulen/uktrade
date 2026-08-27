# BASIC CHECK FOR API RESPONSE STATUS =============================================================

#' A function to check the API's response. Used within `load_*()` functions.
#' @param resp The API response obtained from https://api.uktradeinfo.com, as
#'   returned by `httr2::req_perform()`.
#'
#' @importFrom httr2 resp_status
#' @importFrom httr2 resp_body_json

check_status <- function(resp){

  status <- httr2::resp_status(resp)

  if(status > 399 && status < 500){ stop(
    paste0(
      "The API returned an error with status code ",
      status,
      " (a client-side error).",
      " Are you sure you specified the request correctly?"),
    call. = FALSE) }

  if(status > 499){ stop(
    paste0("The API returned an error with status code ",
           status,
           " (a server-side error).",
           " Please try again later."),
    call. = FALSE) }

  if(length(httr2::resp_body_json(resp, simplifyVector = TRUE)$value) == 0){

    warning(
      paste0("The API returned an empty dataset (without error).",
             " Are you sure you specified the request correctly?"),
      call. = FALSE
    )

  }

}
