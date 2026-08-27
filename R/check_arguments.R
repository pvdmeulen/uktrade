# INPUT VALIDATION HELPERS =========================================================================
#
# These are used internally within `load_ots()`, `load_rts()`, and
# `load_custom()` to catch bad arguments early with an informative error,
# rather than letting them fail confusingly deep inside a filter string or
# a dplyr join - or worse, silently produce an empty/wrong result. None of
# these make an API call, so they're free to run up front.

#' Check a single TRUE/FALSE argument.
#' @param value The value to check. NULL is allowed (treated as "not set").
#' @param name The argument name, used in the error message.
check_logical_arg <- function(value, name){

  if(!is.null(value) && (!is.logical(value) || length(value) != 1 || is.na(value))){
    stop("`", name, "` must be either TRUE or FALSE.", call. = FALSE)
  }

}

#' Check the `output` argument used across all load_*() functions.
#' @param output The `output` argument.
check_output_arg <- function(output){

  if(!is.null(output) && (length(output) != 1 || !(output %in% c("tibble", "df")))){
    stop(
      "`output` must be either \"tibble\" or \"df\", not ",
      paste0("\"", output, "\"", collapse = ", "), ".",
      call. = FALSE
    )
  }

}

#' Check the `flow` argument used in load_ots() and load_rts().
#' @param flow The `flow` argument.
#' @param valid The set of flow codes actually valid for the calling
#'   function. Defaults to 1:4 (all four OTS flow codes). `load_rts()`
#'   passes `3:4`, since RTS data is only ever populated for those two
#'   codes - see its documentation for details.
check_flow_arg <- function(flow, valid = 1:4){

  if(!is.null(flow) && (!is.numeric(flow) || !all(flow %in% valid))){

    flow_labels <- c(
      `1` = "1 (EU imports)", `2` = "2 (EU exports)",
      `3` = "3 (non-EU imports)", `4` = "4 (non-EU exports)"
    )

    stop(
      "`flow` must be one or more of ",
      paste(flow_labels[as.character(valid)], collapse = ", "), ".",
      call. = FALSE
    )
  }

}

#' Check the `month` argument used in load_ots() and load_rts().
#' @param month The `month` argument.
check_month_arg <- function(month){

  if(is.null(month)){ return(invisible(TRUE)) }

  if(!is.numeric(month)){
    stop("`month` must be a numeric vector in the form YYYYMM.", call. = FALSE)
  }

  if(length(month) > 2){
    stop(
      "`month` must be a single value, or a vector of two values ",
      "(a minimum and a maximum), not ", length(month), " values.",
      call. = FALSE
    )
  }

  if(length(month) == 2 && month[1] > month[2]){
    stop(
      "The first element of `month` (the minimum) must not be greater ",
      "than the second element (the maximum). Did you mean c(",
      month[2], ", ", month[1], ")?",
      call. = FALSE
    )
  }

}

#' Check the `country` argument used in load_ots() and load_rts().
#' @param country The `country` argument.
check_country_arg <- function(country){

  if(!is.null(country) && !all(grepl("^[A-Za-z]{2}$", country))){
    stop(
      "`country` must be one or more 2-letter ISO country codes ",
      "(e.g. \"AU\", \"US\").",
      call. = FALSE
    )
  }

}

#' Check the `region` argument used in load_ots() and load_rts().
#' @param region The `region` argument.
check_region_arg <- function(region){

  valid_regions <- c(
    "Asia and Oceania", "Eastern Europe exc EU", "European Union",
    "Latin America and Caribbean", "Middle East and N Africa",
    "North America", "Sub-Saharan Africa", "Western Europe exc EU",
    "Western Europe exc EC", "Low Value Trade", "Stores and Provisions",
    "Confidential Region"
  )

  if(!is.null(region) && !all(region %in% valid_regions)){
    stop(
      "`region` contains invalid value(s): ",
      paste0("\"", setdiff(region, valid_regions), "\"", collapse = ", "),
      ". Must be one or more of: ",
      paste0("\"", valid_regions, "\"", collapse = ", "), ".",
      call. = FALSE
    )
  }

}

#' Check the `uk_country` argument used in load_rts().
#' @param uk_country The `uk_country` argument.
check_uk_country_arg <- function(uk_country){

  valid_uk_countries <- c(
    "England", "Wales", "Scotland", "Northern Ireland", "Unallocated"
  )

  if(!is.null(uk_country) && !all(uk_country %in% valid_uk_countries)){
    stop(
      "`uk_country` contains invalid value(s): ",
      paste0("\"", setdiff(uk_country, valid_uk_countries), "\"", collapse = ", "),
      ". Must be one or more of: ",
      paste0("\"", valid_uk_countries, "\"", collapse = ", "), ".",
      call. = FALSE
    )
  }

}

#' Check the `suppression` argument used in load_ots().
#' @param suppression The `suppression` argument.
check_suppression_arg <- function(suppression){

  if(!is.null(suppression) && (!is.numeric(suppression) || !all(suppression %in% 1:5))){
    stop(
      "`suppression` must be one or more integers between 1 and 5.",
      call. = FALSE
    )
  }

}
