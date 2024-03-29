# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# LOAD_OTS FUNCTION ===============================================================================
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' A function for loading OTS data via HMRC's API.
#' @param month The month(s) to be loaded in the form of a vector of two integers (YYYYMM), where the first element is the minimum date, and second the maximum date. Defaults to NULL (all months).
#' @param flow The trade flow to be loaded. Takes one ore more integers (1, 2, 3, and/or 4), where 1 is EU imports, 2 is EU exports, 3 is non-EU imports, and 4 is non-EU exports. Defaults to NULL (all flows).
#' @param commodity One or more HS2, HS4, HS6, or CN8 commodity codes in the form of a numeric or character vector. Defaults to NULL (all commodities). Any missing leading zeros will be automatically added.
#' @param sitc One or more SITC1, SITC2, SITC3, SITC4, or SITC5 commodity codes in the form of a character vector. Defaults to NULL (all commodities).
#' @param country One or more destination or origin countries by their 2-letter ISO code. Defaults to NULL (all countries).
#' @param region One or more destination or origin regions. Defaults to NULL (all regions). Takes one or more of the following broad categories: "Asia and Oceania", "Eastern Europe exc EU", "European Union", "Latin America and Caribbean", "Middle East and N Africa", "North America", "Sub-Saharan Africa", "Western Europe exc EU", "Western Europe exc EC", "Low Value Trade", "Stores and Provisions", and/or "Confidential Region".
#' @param uk_port One or more departure or arrival ports by their three-letter code (only available for trade with non-EU countries prior to 2021, and all trade post-2021). Defaults to NULL (all ports in the UK).
#' @param suppression One or more suppression codes. Takes one or more integers between 1 and 5 (see HMRC API guidance for information). Defaults to NULL (all available results).
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
#' @importFrom rlang .data
#'
#' @keywords hmrc overseas trade statistics api data
#' @rdname load_ots
#' @export
#'
#' @return Returns a dataframe or tibble
#' @examples
#' \dontrun{
#' # Obtaining all trade of single malt Scotch whisky and bottled gin between in
#' # 2019 via the OTS endpoint:
#'
#' load_ots(month = c(201901, 201912), commodity = c(22083030, 22085011))
#'
#' }

# Function:

load_ots <- function(month = NULL,
                     flow = NULL,
                     commodity = NULL,
                     sitc = NULL,
                     country = NULL,
                     region = NULL,
                     uk_port = NULL,
                     suppression = NULL,
                     join_lookup = TRUE,
                     print_url = FALSE,
                     output = "tibble",
                     skip_interval = 4e4,
                     use_proxy = FALSE,
                     ...
                     ){

  # If no commodities are chosen, load all (detailed):
  if(all(is.null(c(commodity, sitc))) | any(is.element(commodity, 0)) & is.null(sitc)){
    message(
      "Loading detailed trade data for all commodities. This may take a while."
      )
    }

  # Check commodity selection:
  if(length(commodity) > 1 & any(is.element(commodity, 0))){
    stop(
      "Select a collection of commodities or `NULL` for all goods (not both).")
  }

  # Check SITC codes are characters selection:
  if(!is.null(sitc) & !is.character(sitc)){
    stop(
      "Specify your SITC code(s) in <character> format.")
  }

  # Check for internet:
  check_internet()

  # Custom # of requests and time taken:
  request <- 1
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
        country_region_lookup$CountryCodeAlpha, country),
        "CountryId"]))

      }

  chosen_region_id <- if(is.null(region)){

    NULL

  } else {

    unique(c(country_region_lookup[is.element(
      country_region_lookup$Area1a, region
      ), "RegionId"]))

    }

  # Build filter ---------------------------------------------------------------

  # Put filter arguments in a list:
  args_list <- list(FlowTypeId = flow, MonthId = month, CommodityId = commodity,
                    CommoditySitcId = sitc, RegionId = chosen_region_id,
                    CountryId = chosen_country_id, PortId = uk_port,
                    SuppressionIndex = suppression)

  # Take out NULL arguments from filter:
  args_list[sapply(args_list, is.null)] <- NULL

  # Build filter:
  filter <- list()

  for(name in names(args_list)){

    filter[paste0(name)] <- args_list[paste0(name)]

    filter[paste0(name)] <- create_filter(filter[paste0(name)])

  }

  filter <- paste0(filter, collapse = " and ")

  # OTS data -------------------------------------------------------------------

  # Load OTS data:
  ots_data <- load_custom(endpoint = "OTS", custom_search = paste0("?$filter=",
                                                                   filter),
                          output = output, request = request, timer = timer,
                          skip_interval = skip_interval, print_url = print_url,
                          use_proxy = use_proxy, ...)

  if(join_lookup == FALSE) { return(ots_data) } else {

    # Commodity lookup ---------------------------------------------------------

    # Extract from the filter only those items with (CommodityId ... ) or
    # (CommoditySitcId ... ):

    # How many items are in the filter?

    commodity_filter <- args_list["CommodityId"]
    commodity_filter[sapply(commodity_filter, is.null)] <- NULL

    # If there 1 or more, apply a filter:

    commodity_filter <- if(length(commodity_filter) == 0){""} else{

      paste0("?$filter=", paste0(stringr::str_extract_all(
        filter,"\\(CommodityId[^()]+\\)")[[1]], collapse = " or ")
        )

    }

    # Load data:
    commodity_lookup <- load_custom(endpoint = "Commodity",
                                    custom_search = commodity_filter,
                                    output = output,
                                    request = request,
                                    timer = timer,
                                    skip_interval = skip_interval,
                                    print_url = FALSE,
                                    use_proxy = use_proxy, ...)

    # Remove potential odata column:

    commodity_lookup$`@odata.type` <- NULL

    # SITC lookup --------------------------------------------------------------

    sitc_filter <- args_list["CommoditySitcId"]
    sitc_filter[sapply(sitc_filter, is.null)] <- NULL

    sitc_filter <- if(length(sitc_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(
        filter, "\\(CommoditySitcId[^()]+\\)")[[1]], collapse = " or "))

    }

    sitc_lookup <- load_custom(endpoint = "SITC",
                               custom_search = sitc_filter,
                               output = output,
                               request = request,
                               timer = timer,
                               skip_interval = skip_interval,
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
                               timer = timer,
                               skip_interval = skip_interval,
                               print_url = FALSE,
                               use_proxy = use_proxy, ...)

    # Remove potential odata column:

    flow_lookup$`@odata.type` <- NULL

    # Port lookup --------------------------------------------------------------

    port_filter <- args_list["PortId"]
    port_filter[sapply(port_filter, is.null)] <- NULL

    port_filter <- if(length(port_filter) == 0) {""} else {

      paste0("?$filter=", paste0(stringr::str_extract_all(
        filter, "\\(PortId[^()]+\\)"
        )[[1]], collapse = " and "))

    }

    port_lookup <- load_custom(endpoint = "Port",
                               custom_search = port_filter,
                               output = output,
                               request = request,
                               timer = timer,
                               skip_interval = skip_interval,
                               print_url = FALSE,
                               use_proxy = use_proxy, ...)

    # Remove potential odata column:

    port_lookup$`@odata.type` <- NULL

    # Suppression lookup -------------------------------------------------------

    supp_lookup <- data.frame(
      "SuppressionIndex" = c(1, 2, 3, 4, 5),
      "SuppressionDesc" = c(
        "Complete suppression, where no information is published.",
        "Suppression of countries and ports, where only the overall total value (GBP) and quantity (kg) are published.",
        "Suppression of countries, ports and total trade quantity, where only the overall total value is published.",
        "Suppression of quantity for countries and ports, where the overall total value and quantity are published, but where a country and port breakdown is only available for value.",
        "Suppression of quantity for countries, ports and total trade, where no information on quantity is published, but a full breakdown of value is available."
      )
    )

    # Join ---------------------------------------------------------------------

    ots_data <- ots_data %>%
      dplyr::left_join(flow_lookup, by = "FlowTypeId") %>%
      dplyr::left_join(commodity_lookup, by = "CommodityId") %>%
      dplyr::left_join(sitc_lookup, by = "CommoditySitcId") %>%
      dplyr::left_join(country_region_lookup, by = "CountryId") %>%
      dplyr::left_join(port_lookup, by = "PortId") %>%
      dplyr::left_join(supp_lookup, by = "SuppressionIndex") %>%
      # Put data in an order that makes more sense:
      dplyr::select(
        dplyr::contains("MonthId"),
        dplyr::contains("FlowTypeId"),
        dplyr::contains("FlowTypeDescription"),
        dplyr::contains("SuppressionIndex"),
        dplyr::contains("SuppressionDesc"),
        dplyr::contains("Hs2"),
        dplyr::contains("Hs4"),
        dplyr::contains("Hs6"),
        dplyr::contains("Cn8"),
        dplyr::contains("Sitc1"),
        dplyr::contains("Sitc2"),
        dplyr::contains("Sitc3"),
        dplyr::contains("Sitc4"),
        dplyr::contains("Area1"),
        dplyr::contains("Area2"),
        dplyr::contains("Area3"),
        dplyr::contains("Area5a"),
        dplyr::contains("CountryId"),
        dplyr::contains("CountryCodeNumeric"),
        dplyr::contains("CountryCodeAlpha"),
        dplyr::contains("CountryName"),
        dplyr::contains("PortId"),
        dplyr::contains("PortCodeNumeric"),
        dplyr::contains("PortCodeAlpha"),
        dplyr::contains("PortName"),
        dplyr::contains("Value"),
        dplyr::contains("NetMass"),
        dplyr::contains("SuppUnit")
      )

    ots_data <- if(output == "df") {

      as.data.frame(ots_data)

    } else if(output == "tibble") {

      dplyr::as_tibble(ots_data)

      }

    return(ots_data)

  } # end of join_lookup == TRUE

} # end of function
