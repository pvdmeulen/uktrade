# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# LOAD_OTS FUNCTION ===============================================================================
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' A function for loading OTS data via HMRC's API.
#' @param month The month(s) to be loaded in the form of one or more integers of the format YYYYMM. Defaults to NULL (all months).
#' @param flow The trade flow to be loaded. Takes one ore more integers (1, 2, 3, and/or 4), where 1 is EU imports, 2 is EU exports, 3 is non-EU imports, and 4 is non-EU exports. Defaults to NULL (all flows).
#' @param commodity One or more HS2, HS4, HS6, or CN8 commodity codes in the form of a numeric vector. Defaults to NULL (all commodities).
#' @param sitc One or more SITC1, SITC2, SITC4, or SITC5 commodity codes in the form of a numeric vector. Defaults to NULL (all commodities).
#' @param country One or more destination or origin countries by their 2-letter ISO code. Defaults to NULL (all countries).
#' @param region One or more destination or origin regions. Defaults to NULL (all regions). Takes one or more of the following broad categories: "Asia and Oceania", "Eastern Europe exc EU", "European Union", "Latin America and Caribbean", "Middle East and N Africa", "North America", "Sub-Saharan Africa", "Western Europe exc EU", "Western Europe exc EC", "Low Value Trade", "Stores and Provisions", and/or "Confidential Region".
#' @param port One or more departure or arrival ports (only available for trade with non-EU countries prior to 2021, and all trade post-2021). Defaults to NULL (all ports).
#' @param suppression One or more suppression codes. Takes one or more integers between 1 and 5 (see HMRC API guidance for information). Defaults to NULL (all available results).
#' @param output A character specifying if a tibble ("tibble") or dataframe ("df") should be returned. Defaults to "tibble".
#' @param join_lookup A logical value indicating whether results should be joined with lookups from the API. Defaults to TRUE. Setting to FALSE will return a smaller but less human-readable dataframe containing only codes.
#'
#' @importFrom dplyr left_join
#' @importFrom dplyr bind_rows
#' @importFrom dplyr as_tibble
#' @importFrom magrittr `%>%`
#'
#' @keywords hmrc overseas trade statistics api data
#' @rdname load_ots
#' @export
#'
#' @return Returns a dataframe or tibble
#' @examples
#' \dontrun{
#' # Obtaining all trade of single malt Scotch whisky and bottled gin between in 2019 via the OTS endpoint:
#' data <- load_ots(month = 201901:201912, commodity = c(22083030, 22085011))
#' }

# Function:

load_ots <- function(month = NULL, flow = c(1, 2, 3, 4), commodity = NULL, sitc = NULL, country = NULL, region = NULL,
                     port = NULL, suppression = NULL, join_lookup = TRUE, output = "tibble"){

  # If no commodities are chosen, load all (detailed):

  if(is.null(commodity)){ message("Loading detailed export and import data. To load all aggregated trade instead, specify commodity code: `commodity = 0`.") }

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

  # Build filter ----------------------------------------------------------------------------------

  # Put filter arguments in a list:
  args_list <- list(FlowTypeId = flow, MonthId = month, CommodityId = commodity, CommoditySitcId = sitc,
                    RegionId = chosen_region_id, CountryId = chosen_country_id, PortId = port, SuppressionIndex = suppression)

  # Take out NULL arguments from filter:
  args_list[sapply(args_list, is.null)] <- NULL

  # Build filter:
  filter <- paste0("(", mapply(element = args_list, name = names(args_list), FUN = function(element, name)

    # If the filter element is a commodity code
    if(is.element(name, "CommodityId") & is.null(element)){

      # Use all commodity codes greater than or equal to 0 (which is all)
      paste0(name, " ge 0")

      } else {

        # if not, use "FilterName1 eq FilterElement11 or FilterName1 eq FilterElement12" etc.
        paste0(name, " eq ", element, collapse = " or ")

      }

  ), ")", collapse = " and ")

  # OTS data --------------------------------------------------------------------------------------

  # Load OTS data:
  ots_data <- load_custom(endpoint = "OTS", custom_search = paste0("?$filter=", filter), output = output, request = request, timer = timer)

  if(join_lookup == FALSE) { return(ots_data) } else {

    # Commodity lookup ----------------------------------------------------------------------------

    # Extract from the filter only those items with (CommodityId ... ) or (CommoditySitcId ... ):

    # How many items are in the filter?

    commodity_filter <- args_list["CommodityId"]
    commodity_filter[sapply(commodity_filter, is.null)] <- NULL

    # If there 1 or more, apply a filter:

    commodity_filter <- if(length(commodity_filter) == 0){""} else{

      paste0("?$filter=", paste0(stringr::str_extract_all(filter, "\\(CommodityId[^()]+\\)")[[1]], collapse = " and "))

    }

    # Load data:
    commodity_lookup <- load_custom(endpoint = "Commodity", custom_search = commodity_filter, output = output, request = request, timer = timer)

    # Remove potential odata column:

    commodity_lookup$`@odata.type` <- NULL

    # SITC lookup ---------------------------------------------------------------------------------

    sitc_filter <- args_list["CommoditySitcId"]
    sitc_filter[sapply(sitc_filter, is.null)] <- NULL

    sitc_filter <- if(length(sitc_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(filter, "\\(CommoditySitcId[^()]+\\)")[[1]], collapse = " and "))

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

    # Port lookup ---------------------------------------------------------------------------------

    port_filter <- args_list["PortId"]
    port_filter[sapply(port_filter, is.null)] <- NULL

    port_filter <- if(length(port_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(filter, "\\(PortId[^()]+\\)")[[1]], collapse = " and "))

    }

    port_lookup <- load_custom(endpoint = "Port", custom_search = port_filter, output = output, request = request, timer = timer)

    # Remove potential odata column:

    port_lookup$`@odata.type` <- NULL

    # Suppression lookup --------------------------------------------------------------------------

    supp_lookup <- data.frame(
      "SuppressionIndex" = c(1, 2, 3, 4, 5),
      "SuppressionDesc" = c(
        "Complete suppression, where no information is published.",
        "Suppression of countries and ports, where only the overall total value (£ sterling) and quantity (kg) are published.",
        "Suppression of countries, ports and total trade quantity, where only the overall total value is published.",
        "Suppression of quantity for countries and ports, where the overall total value and quantity are published, but where a country and port breakdown is only available for value.",
        "Suppression of quantity for countries, ports and total trade, where no information on quantity is published, but a full breakdown of value is available."
      )
    )

    # Join ----------------------------------------------------------------------------------------

    library(dplyr)

    ots_data <- ots_data %>%
      left_join(flow_lookup, by = "FlowTypeId") %>%
      left_join(commodity_lookup, by = "CommodityId") %>%
      left_join(sitc_lookup, by = "CommoditySitcId") %>%
      left_join(country_region_lookup, by = "CountryId") %>%
      left_join(port_lookup, by = "PortId") %>%
      left_join(supp_lookup, by = "SuppressionIndex") %>%
      # Put data in an order that makes more sense:
      select(
        MonthId, FlowTypeId, FlowTypeDescription,
        SuppressionIndex, SuppressionDesc,
        contains("Hs2"), contains("Hs4"), contains("Hs6"), contains("Cn8"),
        contains("Sitc1"), contains("Sitc2"), contains("Sitc3"), contains("Sitc4"),
        contains("Area1"), contains("Area2"), contains("Area3"), contains("Area5a"),
        CountryId, CountryCodeNumeric, CountryCodeAlpha, CountryName,
        PortId, PortCodeNumeric, PortCodeAlpha, PortName
      )

    ots_data <- if(output == "df") { dplyr::bind_rows(ots_data) } else if(output == "tibble") { dplyr::as_tibble(dplyr::bind_rows(ots_data)) }

    return(ots_data)

  } # end of join_lookup == TRUE

} # end of function
