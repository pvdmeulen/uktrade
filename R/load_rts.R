# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# LOAD_RTS FUNCTION ===============================================================================
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' A function for loading RTS data via HMRC's API.
#' @param month The month(s) to be loaded in the form of one or more integers of the format YYYYMM. Defaults to NULL (all months).
#' @param flow The trade flow to be loaded. Takes one ore more integers (1, 2, 3, and/or 4), where 1 is EU imports, 2 is EU exports, 3 is non-EU imports, and 4 is non-EU exports. Defaults to NULL (all flows).
#' @param sitc One or more SITC2 commodity codes in the form of a numeric vector. Defaults to NULL (all commodities).
#' @param country One or more destination or origin countries by their 2-letter ISO code. Defaults to NULL (all countries).
#' @param region One or more destination or origin regions. Defaults to NULL (all regions). Takes one or more of the following broad categories: "Asia and Oceania", "Eastern Europe exc EU", "European Union", "Latin America and Caribbean", "Middle East and N Africa", "North America", "Sub-Saharan Africa", "Western Europe exc EU", "Western Europe exc EC", "Low Value Trade", "Stores and Provisions", and/or "Confidential Region".
#' @param uk_country One or more destination or origin UK countries. Defaults to NULL (all countries). Takes one or more of the following: "England", "Wales", "Scotland", "Northern Ireland", and/or "Unallocated". England may have multiple regions within it, and Unallocated may be split between known and unknown.
#' @param output A character specifying if a tibble ("tibble") or dataframe ("df") should be returned. Defaults to "tibble".
#' @param join_lookup A logical value indicating whether results should be joined with lookups from the API. Defaults to TRUE. Setting to FALSE will return a smaller but less human-readable dataframe containing only codes.
#'
#' @importFrom dplyr left_join
#' @importFrom dplyr bind_rows
#' @importFrom dplyr as_tibble
#' @importFrom magrittr `%>%`
#'
#' @keywords hmrc regional trade statistics api data
#' @rdname load_rts
#' @export
#'
#' @return Returns a dataframe or tibble
#' @examples
#' \dontrun{
#' # Obtaining all trade of SITC2 code 00 - Live animals in 2019 via the RTS endpoint:
#' data <- load_rts(month = 201901:201912, sitc = 00)
#' }

# Function:

load_rts <- function(month = NULL, flow = c(1, 2, 3, 4), sitc = NULL, country = NULL, region = NULL,
                     uk_country = NULL, join_lookup = TRUE, output = "tibble"){

  # If no commodities are chosen, load all (detailed):

  if(is.null(commodity)){ message("Loading detailed export and import data. To load all aggregated trade instead, specify commodity code: `sitc = -1`.") }

  # Check for internet:
  check_internet()

  # Custom # of requests and time taken:
  request <- 0
  timer <- proc.time()

  # Country and region lookup ---------------------------------------------------------------------

  # Needs to be loaded upfront since function argument is specified in ISO codes:

  country_region_lookup <- load_custom(endpoint = "Country", output = output, request = request, timer = timer)

  chosen_country_id <- if(is.null(country)){ NULL } else { unique(c(country_region_lookup[is.element(country_region_lookup$CountryCodeAlpha, country), "CountryId"])) }
  chosen_region_id <- if(is.null(region)){ NULL } else { unique(c(country_region_lookup[is.element(country_region_lookup$Area1a, region), "RegionId"])) }

  # UK country lookup -----------------------------------------------------------------------------

  ukcountry_lookup <- load_custom(endpoint = "Region", output = output, request = request, timer = timer)

  # Distinguish UK country/region from destination/origin region (e.g. EU):
  colnames(ukcountry_lookup) <- paste0("Gov",  colnames(ukcountry_lookup))

  chosen_uk_country_id <- if(is.null(uk_country)){ NULL } else { unique(c(ukcountry_lookup[is.element(ukcountry_lookup$GovRegionGroupName, uk_country), "GovRegionId"])) }

  # Build filter ----------------------------------------------------------------------------------

  # Put filter arguments in a list:
  args_list <- list(FlowTypeId = flow, MonthId = month, CommoditySitc2Id = sitc,
                    RegionId = chosen_region_id, CountryId = chosen_country_id, GovRegionId = chosen_uk_country_id)

  # Take out NULL arguments from filter:
  args_list[sapply(args_list, is.null)] <- NULL

  # Build filter:
  filter <- paste0("(", mapply(element = args_list, name = names(args_list), FUN = function(element, name)

    # If the filter element for commodity code is NULL:
    if(is.element(name, "CommodityId") & is.null(element)){

      # Use all commodity codes greater than or equal to -1 (which is all)
      paste0(name, " ge -1")

      } else {

        # if not, use "FilterName1 eq FilterElement11 or FilterName1 eq FilterElement12" etc.
        paste0(name, " eq ", element, collapse = " or ")

      }

  ), ")", collapse = " and ")

  # RTS data --------------------------------------------------------------------------------------

  # Load RTS data:
  rts_data <- load_custom(endpoint = "RTS", custom_search = paste0("?$filter=", filter), output = output, request = request, timer = timer)

  if(join_lookup == FALSE) { return(rts_data) } else {

    # SITC lookup ---------------------------------------------------------------------------------

    sitc_filter <- args_list["CommoditySitc2Id"]
    sitc_filter[sapply(sitc_filter, is.null)] <- NULL

    sitc_filter <- if(length(sitc_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(filter, "\\(CommoditySitc2Id[^()]+\\)")[[1]], collapse = " and "))

    }

    sitc_lookup <- load_custom(endpoint = "SITC", custom_search = sitc_filter, output = output, request = request, timer = timer)

    # Remove potential odata column:

    sitc_lookup$`@odata.type` <- NULL

    # Flow lookup ---------------------------------------------------------------------------------

    flow_filter <- args_list["FlowTypeId"]
    flow_filter[sapply(flow_filter, is.null)] <- NULL

    flow_filter <- if(length(flow_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(filter, "\\(FlowTypeId[^()]+\\)")[[1]], collapse = " and "))

    }

    flow_lookup <- load_custom(endpoint = "FlowType", custom_search = flow_filter, output = output, request = request, timer = timer)

    # Remove potential odata column:

    flow_lookup$`@odata.type` <- NULL

    # Join ----------------------------------------------------------------------------------------

    library(dplyr)

    rts_data <- rts_data %>%
      left_join(flow_lookup, by = "FlowTypeId") %>%
      left_join(sitc_lookup, by = "CommoditySitc2Id") %>%
      left_join(country_region_lookup, by = "CountryId") %>%
      left_join(ukcountry_lookup, by = "GovRegionId") %>%
      # Put data in an order that makes more sense:
      select(
        MonthId, FlowTypeId, FlowTypeDescription,
        contains("Sitc1"), contains("Sitc2"),
        contains("GovRegion"),
        contains("Area1"), contains("Area2"), contains("Area3"), contains("Area5a"),
        CountryId, CountryCodeNumeric, CountryCodeAlpha, CountryName
      )

    rts_data <- if(output == "df") { as.data.frame(rts_data) } else if(output == "tibble") { dplyr::as_tibble(rts_data) }

    return(rts_data)

  } # end of join_lookup == TRUE

} # end of function
