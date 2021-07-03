# BASIC FILTER CREATION HELPER FUNCTION ===========================================================

#' A function to create a filter from function arguments. Used within `load_ots()` and `load_rts` functions.
#' @param list A list of arguments obtained within the `load_rts()` or `load_ots()` functions.
#'
#' @importFrom stringr str_pad
#' @importFrom stringr str_detect
#' @importFrom stringr str_length

create_filter <- function(list){

  name <- names(list)
  element <- unlist(list[paste0(name)])

  templist <- list()

  if (name == "CommodityId") {
    # If HS2, HS4, HS6 codes are full (w/o leading zeros), pad them to be 8
    # characters long and combine with a 'greater than or equal to ....0000 and
    # less than or equal to ...9999' type filter:

    templist["Full HS246 Codes"] <-
      paste0(
        "(",
        name,
        " ge ",
        stringr::str_pad(
          element[stringr::str_length(element) %in% c(2, 4, 6)],
          pad = 0,
          side = "right",
          width = 8
        ),
        " and ",
        name,
        " le ",
        stringr::str_pad(
          element[stringr::str_length(element) %in% c(2, 4, 6)],
          pad = 9,
          side = "right",
          width = 8
        ),
        collapse = " or ",
        ")"
      )

    # If HS2, HS4, HS6 codes are partial (w/ leading zeros), pad them to be
    # 7 characters long and combine with a 'greater than or equal to ...0000 and
    # less than or equal to ..9999' type filter:

    templist["Partial HS246 Codes"] <-
      paste0(
        "(",
        name,
        " ge ",
        stringr::str_pad(
          element[stringr::str_length(element) %in% c(1, 3, 5)],
          pad = 0,
          side = "right",
          width = 7
        ),
        " and ",
        name,
        " le ",
        stringr::str_pad(
          element[stringr::str_length(element) %in% c(1, 3, 5)],
          pad = 9,
          side = "right",
          width = 7
        ),
        collapse = " or ",
        ")"
      )

    # If there are CN8 codes, create a simple 'equal to ........ or equal
    # to ........' type filter:

    templist["CN8 Codes"] <-
      paste0("(", paste0(name, " eq ", element[
        stringr::str_length(element) %in% c(7, 8)
        ], collapse = " or "), ")")

    # Combine these types into one string:

    list[paste0(name)] <-
      paste0(templist[stringr::str_detect(templist, "[0-9]")],
             collapse = " or ")

    remove(templist)

  } else if (name %in% c("MonthId", "CommoditySitc2Id")) {
    # The month filter consists of a 'greater than or equal to ...... and less
    # than or equal to ......' type filter to keep the size of the URL down.
    # This also applies to the SITC2 filter in the load_rts() function.

    list[paste0(name)] <-
      paste0(
        "(",
        name,
        " ge ",
        min(element, na.rm = TRUE),
        " and ",
        name,
        " le ",
        max(element, na.rm = TRUE),
        ")",
        collapse = " "
      )

  } else {
    # Other filters have a simple 'equal to ........ or
    # equal to ........' type filter:

    list[paste0(name)] <-
      paste0("(", paste0(name, " eq ", element, collapse = " or "), ")")

  }

  # Return the list:

  return(list)

}
