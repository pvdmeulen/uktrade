# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# LOAD_RTS FUNCTION ===============================================================================
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' A function for loading RTS data via HMRC's API.
#' @param month The month(s) to be loaded in the form of a vector of two integers (YYYYMM), where the first element is the minimum date, and second the maximum date. Defaults to NULL (all months).
#' @param flow The trade flow to be loaded. Takes one ore more integers (1, 2, 3, and/or 4), where 1 is EU imports, 2 is EU exports, 3 is non-EU imports, and 4 is non-EU exports. Defaults to NULL (all flows).
#' @param sitc The range of SITC2 commodity codes to be loaded (min and max), in the form of a numeric vector. Defaults to NULL (all commodities).
#' @param country One or more destination or origin countries by their 2-letter ISO code. Defaults to NULL (all countries).
#' @param region One or more destination or origin regions. Defaults to NULL (all regions). Takes one or more of the following broad categories: "Asia and Oceania", "Eastern Europe exc EU", "European Union", "Latin America and Caribbean", "Middle East and N Africa", "North America", "Sub-Saharan Africa", "Western Europe exc EU", "Western Europe exc EC", "Low Value Trade", "Stores and Provisions", and/or "Confidential Region".
#' @param uk_country One or more destination or origin UK countries. Defaults to NULL (all countries). Takes one or more of the following: "England", "Wales", "Scotland", "Northern Ireland", and/or "Unallocated". England may have multiple regions within it, and Unallocated may be split between known and unknown.
#' @param join_lookup A logical value indicating whether results should be joined with lookups from the API. Defaults to TRUE. Setting to FALSE will return a smaller but less human-readable dataframe containing only codes.
#' @param print_url A logical. Defaults to FALSE. Setting this to TRUE will print the URL(s) used to load the trade data to the console.
#' @param output A character specifying if a tibble ("tibble") or dataframe ("df") should be returned. Defaults to "tibble".
#' @param skip_interval Passed to load_custom(). A non-negative integer value showing the skip interval for paginated results. Defaults to 40,000 rows.
#' @param use_proxy A logical. Defaults to FALSE. Setting this to TRUE will allow the use of a proxy connection using `use_proxy()` from `httr`.
#' @param ... Optional arguments to be passed along to `use_proxy()` when using a proxy connection (by setting use_proxy to TRUE). See the `httr` documentation for more details.
#'
#' @importFrom dplyr left_join
#' @importFrom dplyr select
#' @importFrom dplyr bind_rows
#' @importFrom dplyr as_tibble
#' @importFrom magrittr `%>%`
#' @importFrom stringr str_extract_all
#' @importFrom stringr str_replace
#' @importFrom stringr str_replace_all
#' @importFrom rlang .data
#'
#' @keywords hmrc regional trade statistics api data
#' @rdname load_rts
#' @export
#'
#' @return Returns a dataframe or tibble
#' @examples
#' \dontrun{
#' # Obtaining all trade from SITC2 code 00 - Live animals to
#' # 11 - Beverages in 2019 via the RTS endpoint:
#'
#' load_rts(month = c(201901, 201912), sitc = c(00, 11))
#'
#' }

# Function:

load_rts <- function(month = NULL,
                     flow = c(1, 2, 3, 4),
                     sitc = NULL,
                     country = NULL,
                     region = NULL,
                     uk_country = NULL,
                     join_lookup = TRUE,
                     print_url = FALSE,
                     output = "tibble",
                     skip_interval = 4e4,
                     use_proxy = FALSE,
                     ...
                     ){

  # If no commodities are chosen, load all (detailed):

  if(is.null(sitc)){

    message("Loading trade data for all commodities. This may take a while.")

    }

  # Check for internet:
  check_internet()

  # Custom # of requests and time taken:
  request <- 0
  timer <- proc.time()

  # Country and region lookup --------------------------------------------------

  # Needs to be loaded upfront since argument is specified in ISO codes:

  country_region_lookup <- load_custom(endpoint = "Country", output = output,
                                       request = request, timer = timer,
                                       skip_interval = skip_interval,
                                       print_url = FALSE,
                                       use_proxy = use_proxy, ...)

  chosen_country_id <- if(is.null(country)){

    NULL

    } else {

    unique(c(country_region_lookup[is.element(
      country_region_lookup$CountryCodeAlpha, country), "CountryId"]))

      }

  chosen_region_id <- if(is.null(region)){

    NULL

  } else {

    unique(c(country_region_lookup[is.element(
      country_region_lookup$Area1a, region), "RegionId"]))

    }

  # UK country lookup ----------------------------------------------------------

  ukcountry_lookup <- load_custom(endpoint = "Region",
                                  output = output,
                                  request = request,
                                  timer = timer, skip_interval = skip_interval,
                                  print_url = FALSE,
                                  use_proxy = use_proxy, ...)

  # Distinguish UK country/region from destination/origin region (e.g. EU):
  colnames(ukcountry_lookup) <- paste0("Gov",  colnames(ukcountry_lookup))

  chosen_uk_country_id <- if(is.null(uk_country)){

    NULL

  } else {

    unique(c(ukcountry_lookup[is.element(
      ukcountry_lookup$GovRegionGroupName, uk_country), "GovRegionId"]))

    }

  # Build filter ---------------------------------------------------------------

  # Put filter arguments in a list:
  args_list <- list(FlowTypeId = flow, MonthId = month, CommoditySitc2Id = sitc,
                    RegionId = chosen_region_id, CountryId = chosen_country_id,
                    GovRegionId = chosen_uk_country_id)

  # Take out NULL arguments from filter:
  args_list[sapply(args_list, is.null)] <- NULL

  # Build filter:
  filter <- list()

  for(name in names(args_list)){

    filter[paste0(name)] <- args_list[paste0(name)]

    filter[paste0(name)] <- create_filter(filter[paste0(name)])

  }

  filter <- paste0(filter, collapse = " and ")

  # RTS data -------------------------------------------------------------------
  # Load RTS data:
  rts_data <- load_custom(endpoint = "RTS",
                          custom_search = paste0("?$filter=", filter),
                          output = output,
                          request = request, timer = timer,
                          skip_interval = skip_interval, print_url = print_url,
                          use_proxy = use_proxy, ...)

  if(join_lookup == FALSE) { return(rts_data) } else {

    # SITC lookup --------------------------------------------------------------

    sitc_filter <- args_list["CommoditySitc2Id"]
    sitc_filter[sapply(sitc_filter, is.null)] <- NULL

    sitc_filter <- if(length(sitc_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(
        filter, "\\(CommoditySitc2Id[^()]+\\)"
        )[[1]], collapse = " or "))

    }

    # Rename filter:
    sitc_filter <- stringr::str_replace_all(
      sitc_filter,"CommoditySitc2Id", "CommoditySitcId"
      )

    sitc_lookup <- load_custom(endpoint = "SITC",
                               custom_search = sitc_filter,
                               output = output,
                               request = request,
                               timer = timer, skip_interval = skip_interval,
                               print_url = FALSE,
                               use_proxy = use_proxy, ...)

    # Remove potential odata column:

    sitc_lookup$`@odata.type` <- NULL

    # Flow lookup --------------------------------------------------------------

    flow_filter <- args_list["FlowTypeId"]
    flow_filter[sapply(flow_filter, is.null)] <- NULL

    flow_filter <- if(length(flow_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(
        filter, "\\(FlowTypeId[^()]+\\)"
        )[[1]], collapse = " and "))

    }

    flow_lookup <- load_custom(endpoint = "FlowType",
                               custom_search = flow_filter,
                               output = output,
                               request = request,
                               timer = timer, skip_interval = skip_interval,
                               print_url = FALSE,
                               use_proxy = use_proxy, ...)

    # Remove potential odata column:

    flow_lookup$`@odata.type` <- NULL

    # Join ---------------------------------------------------------------------

    rts_data <- rts_data %>%
      dplyr::left_join(flow_lookup, by = "FlowTypeId") %>%
      dplyr::left_join(sitc_lookup,
                       by = c("CommoditySitc2Id" = "CommoditySitcId")) %>%
      dplyr::left_join(country_region_lookup, by = "CountryId") %>%
      dplyr::left_join(ukcountry_lookup, by = "GovRegionId") %>%
      # Put data in an order that makes more sense:
      dplyr::select(
        .data$MonthId,
        .data$FlowTypeId,
        .data$FlowTypeDescription,
        dplyr::contains("Sitc1"),
        dplyr::contains("Sitc2"),
        dplyr::contains("GovRegion"),
        dplyr::contains("Area1"),
        dplyr::contains("Area2"),
        dplyr::contains("Area3"),
        dplyr::contains("Area5a"),
        .data$CountryId,
        .data$CountryCodeNumeric,
        .data$CountryCodeAlpha,
        .data$CountryName,
        .data$Value,
        .data$NetMass
      )

    rts_data <- if(output == "df") {

      as.data.frame(rts_data)

    } else if(output == "tibble") {

      dplyr::as_tibble(rts_data)

      }

    return(rts_data)

  } # end of join_lookup == TRUE

} # end of function
