# BASIC FILTER CREATION HELPER FUNCTION ===========================================================

#' A function to create a filter from function arguments. Used within `load_ots()` and `load_rts` functions.
#' @param list A list of arguments obtained within the `load_rts()` or `load_ots()` functions.
#'
#' @importFrom stringr str_pad
#' @importFrom stringr str_detect
#' @importFrom stringr str_length

create_filter <- function(list){

  names <- names(list)

  for(name in names){

    element <- unlist(list[paste0(name)])

    if (name == "CommodityId") {

      templist <- list()

      # HS2 codes ---------------------------------------------------------------

      # HS2 codes need to also include Below Threshold Trade Allocation data,
      # and will need to separately include codes ending in ..999999

      # If HS2 codes are full (w/ leading zeros), pad them to be 8
      # characters long and combine with a 'greater than or equal to ....0000 and
      # less than or equal to ...9999' type filter, plus BTTA codes:

      if (any(stringr::str_length(element) == 2)){

        templist["Full HS2 Codes"] <-
          paste0(
            "(",
            name,
            " ge ",
            stringr::str_pad(
              element[stringr::str_length(element) == 2],
              pad = 0,
              side = "right",
              width = 8
            ),
            " and ",
            name,
            " le ",
            stringr::str_pad(
              element[stringr::str_length(element) == 2],
              pad = 9,
              side = "right",
              width = 8
            ), ") or ", name, " eq ", element[stringr::str_length(element) == 2], "9999999",
            collapse = " or "
          )

      }

      # If HS2 codes are partial (w/o leading zeros), pad them to be
      # 7 characters long and combine with a 'greater than or equal to ...0000 and
      # less than or equal to ..9999' type filter, plus BTTA codes:

      if (any(stringr::str_length(element) == 1)) {

        templist["Partial HS2 Codes"] <-
          paste0(
            "(",
            name,
            " ge ",
            stringr::str_pad(
              stringr::str_pad(
                element[stringr::str_length(element) == 1],
                pad = 0,
                side = "right",
                width = 7
              ),
              pad = 0,
              side = "left",
              width = 8
            ),
            " and ",
            name,
            " le ",
            stringr::str_pad(
              stringr::str_pad(
                element[stringr::str_length(element) == 1],
                pad = 9,
                side = "right",
                width = 7
              ),
              pad = 0,
              side = "left",
              width = 8
            ), ") or ", name, " eq 0", element[stringr::str_length(element) == 1], "9999999",
            collapse = " or "
          )

      }

      # HS4/HS6 codes -----------------------------------------------------------

      # No BTTA estimates for these codes.

      # If HS4, HS6 codes are full (w/ leading zeros), pad them to be 8
      # characters long and combine with a 'greater than or equal to ....0000 and
      # less than or equal to ...9999' type filter:

      if (any(stringr::str_length(element) %in% c(4, 6))) {

        templist["Full HS46 Codes"] <-
          paste0(
            "(",
            name,
            " ge ",
            stringr::str_pad(
              element[stringr::str_length(element) %in% c(4, 6)],
              pad = 0,
              side = "right",
              width = 8
            ),
            " and ",
            name,
            " le ",
            stringr::str_pad(
              element[stringr::str_length(element) %in% c(4, 6)],
              pad = 9,
              side = "right",
              width = 8
            ), ")",
            collapse = " or "
          )

      }

      # If HS2, HS4, HS6 codes are partial (w/o leading zeros), pad them to be
      # 7 characters long and combine with a 'greater than or equal to ...0000 and
      # less than or equal to ..9999' type filter:

      if (any(stringr::str_length(element) %in% c(3, 5))) {

        templist["Partial HS46 Codes"] <-
          paste0(
            "(",
            name,
            " ge ",
            stringr::str_pad(
              stringr::str_pad(
                element[stringr::str_length(element) %in% c(3, 5)],
                pad = 0,
                side = "right",
                width = 7
              ),
              pad = 0,
              side = "left",
              width = 8
            ),
            " and ",
            name,
            " le ",
            stringr::str_pad(
              stringr::str_pad(
                element[stringr::str_length(element) %in% c(3, 5)],
                pad = 9,
                side = "right",
                width = 7
              ),
              pad = 0,
              side = "left",
              width = 8
            ), ")",
            collapse = " or "
          )

      }

      # NOTE that we do not strictly need to add leading zeros to codes,
      # since the query itself will remove these when sending the request
      # to the API - for completeness' sake these are included here.

      # If there are CN8 codes, create a simple 'equal to ........ or equal
      # to ........' type filter (w/ or w/o leading zeros):

      if (any(stringr::str_length(element) %in% c(7, 8))) {

        templist["CN8 Codes"] <-
          paste0("(", paste0(name, " eq ", element[
            stringr::str_length(element) %in% c(7, 8)
          ], collapse = " or "), ")")

      }

      # Combine these commodity codes into one string:

      list[paste0(name)] <-
        paste0("(", paste0(templist[stringr::str_detect(templist, "[0-9]")],
                           collapse = " or "), ")")

      remove(templist)

      # Do the same for SITC codes chosen in load_ots() function:

    } else if (name == "CommoditySitcId") {

      templist <- list()

      # SITC2 codes -------------------------------------------------------------

      # SITC2 codes may also contain BTTA estimates - split these out.

      # Assume both 2-digit and 1-digit SITC codes are full (w/ leading zeros),
      # since single-digit and odd SITC codes also exist. Pad them to be 5
      # characters long and combine with a 'greater than or equal to and less than
      # or equal to ...9999' type filter, plus BTTA codes:

      if (any(stringr::str_length(element) %in% 1:2)) {

        templist["SITC12 Codes"] <-
          paste0(
            "(",
            name,
            " ge ",
            stringr::str_pad(
              element[stringr::str_length(element) %in% 1:2],
              pad = 0,
              side = "right",
              width = 5
            ),
            " and ",
            name,
            " le ",
            stringr::str_pad(
              element[stringr::str_length(element) %in% 1:2],
              pad = 9,
              side = "right",
              width = 5
            ), ") or ", name, " eq ", element[stringr::str_length(element) %in% 1:2], "99999",
            collapse = " or "
          )

      }

      # Likewise, assume 3 and 4-digit SITC codes are full (w/ leading zeros). Pad
      # them to be 5 characters long and combine with a 'greater than or equal to
      # and less than or equal to ...9999' type filter:

      if (any(stringr::str_length(element) %in% 3:4)) {

        templist["SITC34 Codes"] <-
          paste0(
            "(",
            name,
            " ge ",
            stringr::str_pad(
              element[stringr::str_length(element) %in% 3:4],
              pad = 0,
              side = "right",
              width = 5
            ),
            " and ",
            name,
            " le ",
            stringr::str_pad(
              element[stringr::str_length(element) %in% 3:4],
              pad = 9,
              side = "right",
              width = 5
            ), ")",
            collapse = " or "
          )

      }

      # If there are any SITC5 codes, create a simple 'equal to ........ or equal
      # to ........' type filter:

      if (any(stringr::str_length(element) == 5)) {

        templist["SITC5 Codes"] <-
          paste0("(", paste0(name, " eq ", element[
            stringr::str_length(element) %in% 5
          ], collapse = " or "), ")")

      }

      # Combine these commodity codes into one string:

      list[paste0(name)] <-
        paste0("(", paste0(templist[stringr::str_detect(templist, "[0-9]")],
                           collapse = " or "), ")")

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


  } # End of for loop

  # Return the list:

  return(list)

}
