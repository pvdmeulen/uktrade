
<!-- README.md is generated from README.Rmd. Please edit that file -->

# uktrade

<!-- badges: start -->

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/pvdmeulen/uktrade/workflows/R-CMD-check/badge.svg)](https://github.com/pvdmeulen/uktrade/actions)
<!-- badges: end -->

The goal of `uktrade` is to provide convenient wrapper functions for
loading HMRC data in R.

## Installation

You can install the latest version of `uktrade` from this GitHub
repository using `devtools`:

``` r
devtools::install_github("pvdmeulen/uktrade")
```

## HMRC data

Her Majesty’s Revenue & Customs (HMRC) is the United Kingdom’s customs
authority. Data on UK trade is available on their
[uktradeinfo.com](https://www.uktradeinfo.com/) website, which is
collected through a combination of customs declarations and Intrastat
surveys (in the case of [some EU trade](https://www.gov.uk/intrastat)).

In the beginning of 2021, the
[uktradeinfo.com](https://www.uktradeinfo.com/) website was updated.
This update also introduced an Application Programming Interface (API)
for accessing bulk trade (and trader) data. For smaller trade data
extracts (\< 30,000 rows), the [online
tool](https://www.uktradeinfo.com/trade-data/) may be sufficient.

For more information on the various API endpoints and options, see
[HMRC’s API
documentation](https://www.uktradeinfo.com/api-documentation/). Note
that this service and the website itself are in beta at the time of
writing - features may still be added or changed (e.g. the [number of
rows per page was
increased](https://www.uktradeinfo.com/news/enhancement-made-to-uktradeinfo-api-service/)
from 30,000 to 40,000 in December 2021).

## This package

This package contains four functions:

| Function        | Description                                           | Status                                         |
|-----------------|-------------------------------------------------------|------------------------------------------------|
| `load_ots()`    | a function for loading Overseas Trade Statistics data | :yellow_circle: experimental (use at own risk) |
| `load_rts()`    | a function for loading Regional Trade Statistics data | :yellow_circle: experimental (use at own risk) |
| `load_trader()` | a function for loading trader data                    | :red_circle: *planned*                         |
| `load_custom()` | a function for loading a custom URL                   | :yellow_circle: experimental (use at own risk) |

All of these functions will output a `dataframe` object (or `tibble`)
with the desired data, and are able to keep track of paginated results
(in batches of 40,000 rows) as well as the API request limit of 60
requests per minute.

The first three are convenient wrapper functions which should make
loading basic datasets easier (with the assumption that further data
manipulation will be done in R after loading the data). Of course, the
API allows for extensive customisation in what data is obtained. For
this purpose, `load_custom()` allows you to specify a custom URL
instead. This allows you to be more specific in your request (and in the
case of trader data, expand specific columns to get more information).

## Example using OTS and RTS data

These functions are convenient wrappers for loading trade data - either
detailed UK trade data using OTS (by CN8 code), or regional UK trade
data using RTS (by SITC2 code). These functions will load the raw data
and optionally join results with lookups obtained from the API (using,
for example, the /Commodity and /Country endpoints). This makes data
easy to read by humans, but also larger (more columns containing text).

### OTS

Loading all UK trade of single malt Scotch whisky (CN8 code 22083030)
and bottled gin (22085011) for 2019 is done like so:

``` r
library(uktrade)
data <- load_ots(month = c(201901, 201912), commodity = c(22083030, 22085011), join_lookup = FALSE,
    output = "tibble")

# Results are now in a tibble (set output to 'df' to obtain a dataframe):
data
#> # A tibble: 4,663 x 10
#>    MonthId FlowT~1 Suppr~2 Commo~3 Commo~4 Count~5 PortId  Value NetMass SuppU~6
#>      <int>   <int>   <int>   <int>   <int>   <int>  <int>  <dbl>   <dbl>   <dbl>
#>  1  201901       1       0  2.21e7   11241       1      0  58499    2329    1002
#>  2  201902       1       0  2.21e7   11241       1      0  58521    1524     659
#>  3  201903       1       0  2.21e7   11241       1      0 113601    3760    1677
#>  4  201904       1       0  2.21e7   11241       1      0 136492    4694    2135
#>  5  201905       1       0  2.21e7   11241       1      0  55862    2826    1228
#>  6  201906       1       0  2.21e7   11241       1      0  61902    3488    1569
#>  7  201907       1       0  2.21e7   11241       1      0 111261   11579    2723
#>  8  201908       1       0  2.21e7   11241       1      0 135419    4335    1972
#>  9  201909       1       0  2.21e7   11241       1      0 138810    9528    2948
#> 10  201910       1       0  2.21e7   11241       1      0 141740    5562    2445
#> # ... with 4,653 more rows, and abbreviated variable names 1: FlowTypeId,
#> #   2: SuppressionIndex, 3: CommodityId, 4: CommoditySitcId, 5: CountryId,
#> #   6: SuppUnit
```

Note that the `month` argument specifies a range in the form of
`c(min, max)`, while the `commodity` argument specifies a collection of
commodities (not a range).

As you can see, results are not easily interpretable as they stand. The
HMRC API also has lookups which can be loaded separately using
`load_custom()`, or joined automatically:

``` r
# Load specific lookups separately:
commodity_lookup <- load_custom(endpoint = "Commodity")

# Or join automatically with the `join_lookup = TRUE` option:
data <- load_ots(month = c(201901, 201912), commodity = c(22083030, 22085011), join_lookup = TRUE)

data
#> # A tibble: 4,663 x 39
#>    MonthId FlowTypeId FlowType~1 Suppr~2 Suppr~3 Hs2Code Hs2De~4 Hs4Code Hs4De~5
#>      <int>      <int> <chr>        <dbl> <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1  201901          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  2  201902          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  3  201903          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  4  201904          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  5  201905          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  6  201906          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  7  201907          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  8  201908          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  9  201909          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#> 10  201910          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#> # ... with 4,653 more rows, 30 more variables: Hs6Code <chr>,
#> #   Hs6Description <chr>, Cn8Code <chr>, Cn8LongDescription <chr>,
#> #   Sitc1Code <chr>, Sitc1Desc <chr>, Sitc2Code <chr>, Sitc2Desc <chr>,
#> #   Sitc3Code <chr>, Sitc3Desc <chr>, Sitc4Code <chr>, Sitc4Desc <chr>,
#> #   Area1 <chr>, Area1a <chr>, Area2 <chr>, Area2a <chr>, Area3 <chr>,
#> #   Area3a <chr>, Area5a <chr>, CountryId <int>, CountryCodeNumeric <chr>,
#> #   CountryCodeAlpha <chr>, CountryName <chr>, PortId <int>, ...
```

Loading aggregate data (such as all spirits, HS4 code 2208) is possible
too (in the background, this is loading commodity codes greater than or
equal to 22080000 and less than or equal to 22089999). You can also see
what URL the code is using by specifying `print_URL = TRUE`:

``` r
data <- load_ots(month = c(201901, 201912), commodity = 2208, join_lookup = TRUE,
    print_url = TRUE)
#> Loading data via the following URL(s):
#> URL 1: https://api.uktradeinfo.com/OTS?$filter=(MonthId ge 201901 and MonthId le 201912) and ((CommodityId ge 22080000 and CommodityId le 22089999))

data
#> # A tibble: 23,466 x 39
#>    MonthId FlowTypeId FlowType~1 Suppr~2 Suppr~3 Hs2Code Hs2De~4 Hs4Code Hs4De~5
#>      <int>      <int> <chr>        <dbl> <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1  201901          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  2  201902          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  3  201903          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  4  201904          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  5  201905          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  6  201906          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  7  201907          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  8  201908          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#>  9  201909          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#> 10  201910          1 "EU Impor~       0 <NA>    22      Bevera~ 2208    Undena~
#> # ... with 23,456 more rows, 30 more variables: Hs6Code <chr>,
#> #   Hs6Description <chr>, Cn8Code <chr>, Cn8LongDescription <chr>,
#> #   Sitc1Code <chr>, Sitc1Desc <chr>, Sitc2Code <chr>, Sitc2Desc <chr>,
#> #   Sitc3Code <chr>, Sitc3Desc <chr>, Sitc4Code <chr>, Sitc4Desc <chr>,
#> #   Area1 <chr>, Area1a <chr>, Area2 <chr>, Area2a <chr>, Area3 <chr>,
#> #   Area3a <chr>, Area5a <chr>, CountryId <int>, CountryCodeNumeric <chr>,
#> #   CountryCodeAlpha <chr>, CountryName <chr>, PortId <int>, ...
```

When loading an HS2 code, or a SITC1 or SITC2 code, so-called Below
Threshold Trade Allocation estimates are also loaded (for EU trade).
These are, roughly, estimated values for those trades which fell below
the Intrastat Survey threshold. At more detailed commodity levels, these
estimates are excluded. BTTA trade estimates have different commodity
codes (9-digit CN codes ending in 9999999, or 7-digit SITC codes ending
in 99999):

``` r
data <- load_ots(month = c(202101, 202103), commodity = "03", join_lookup = TRUE,
    print_url = TRUE)
#> Loading data via the following URL(s):
#> URL 1: https://api.uktradeinfo.com/OTS?$filter=(MonthId ge 202101 and MonthId le 202103) and ((CommodityId ge 03000000 and CommodityId le 03999999) or CommodityId eq 039999999)

library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(stringr)

data %>%
    filter(stringr::str_detect(Sitc4Code, "-"))
#> # A tibble: 54 x 39
#>    MonthId FlowTypeId FlowType~1 Suppr~2 Suppr~3 Hs2Code Hs2De~4 Hs4Code Hs4De~5
#>      <int>      <int> <chr>        <dbl> <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1  202101          1 "EU Impor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  2  202101          2 "EU Expor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  3  202102          2 "EU Expor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  4  202103          2 "EU Expor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  5  202101          1 "EU Impor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  6  202102          1 "EU Impor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  7  202103          1 "EU Impor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  8  202101          2 "EU Expor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#>  9  202102          2 "EU Expor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#> 10  202103          2 "EU Expor~       0 <NA>    <NA>    <NA>    <NA>    <NA>   
#> # ... with 44 more rows, 30 more variables: Hs6Code <chr>,
#> #   Hs6Description <chr>, Cn8Code <chr>, Cn8LongDescription <chr>,
#> #   Sitc1Code <chr>, Sitc1Desc <chr>, Sitc2Code <chr>, Sitc2Desc <chr>,
#> #   Sitc3Code <chr>, Sitc3Desc <chr>, Sitc4Code <chr>, Sitc4Desc <chr>,
#> #   Area1 <chr>, Area1a <chr>, Area2 <chr>, Area2a <chr>, Area3 <chr>,
#> #   Area3a <chr>, Area5a <chr>, CountryId <int>, CountryCodeNumeric <chr>,
#> #   CountryCodeAlpha <chr>, CountryName <chr>, PortId <int>, ...
```

Specifying `commodity = NULL` and `SITC = NULL` will load all
commodities (this may take considerable time). This will also include
so-called non-response estimates, which have negative commodity codes
(and currently cannot be split by e.g. SITC2 or HS2). For example, we
can load all exports to Australia in January 2019:

``` r
data <- load_ots(month = 201901, country = "AU", flow = 4, commodity = NULL, join_lookup = TRUE)
#> Loading detailed trade data for all commodities. This may take a while.

data
#> # A tibble: 4,960 x 39
#>    MonthId FlowTypeId FlowType~1 Suppr~2 Suppr~3 Hs2Code Hs2De~4 Hs4Code Hs4De~5
#>      <int>      <int> <chr>        <dbl> <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1  201901          4 "Non-EU E~       0 <NA>    25      Salt; ~ <NA>    <NA>   
#>  2  201901          4 "Non-EU E~       0 <NA>    28      Inorga~ <NA>    <NA>   
#>  3  201901          4 "Non-EU E~       0 <NA>    29      Organi~ <NA>    <NA>   
#>  4  201901          4 "Non-EU E~       0 <NA>    29      Organi~ <NA>    <NA>   
#>  5  201901          4 "Non-EU E~       0 <NA>    36      Explos~ <NA>    <NA>   
#>  6  201901          4 "Non-EU E~       0 <NA>    39      Plasti~ <NA>    <NA>   
#>  7  201901          4 "Non-EU E~       0 <NA>    39      Plasti~ <NA>    <NA>   
#>  8  201901          4 "Non-EU E~       0 <NA>    39      Plasti~ <NA>    <NA>   
#>  9  201901          4 "Non-EU E~       0 <NA>    39      Plasti~ <NA>    <NA>   
#> 10  201901          4 "Non-EU E~       0 <NA>    39      Plasti~ <NA>    <NA>   
#> # ... with 4,950 more rows, 30 more variables: Hs6Code <chr>,
#> #   Hs6Description <chr>, Cn8Code <chr>, Cn8LongDescription <chr>,
#> #   Sitc1Code <chr>, Sitc1Desc <chr>, Sitc2Code <chr>, Sitc2Desc <chr>,
#> #   Sitc3Code <chr>, Sitc3Desc <chr>, Sitc4Code <chr>, Sitc4Desc <chr>,
#> #   Area1 <chr>, Area1a <chr>, Area2 <chr>, Area2a <chr>, Area3 <chr>,
#> #   Area3a <chr>, Area5a <chr>, CountryId <int>, CountryCodeNumeric <chr>,
#> #   CountryCodeAlpha <chr>, CountryName <chr>, PortId <int>, ...
```

We can also use SITC codes - here, we load all beverage (SITC2 code 11)
exports to Australia in January 2019:

``` r
data <- load_ots(month = 201901, country = "AU", flow = 4, sitc = "11", join_lookup = TRUE)

data
#> # A tibble: 105 x 39
#>    MonthId FlowTypeId FlowType~1 Suppr~2 Suppr~3 Hs2Code Hs2De~4 Hs4Code Hs4De~5
#>      <int>      <int> <chr>        <dbl> <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2201    Waters~
#>  2  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2202    Waters~
#>  3  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2202    Waters~
#>  4  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2202    Waters~
#>  5  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2202    Waters~
#>  6  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2202    Waters~
#>  7  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2202    Waters~
#>  8  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2202    Waters~
#>  9  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2203    Beer m~
#> 10  201901          4 "Non-EU E~       0 <NA>    22      Bevera~ 2203    Beer m~
#> # ... with 95 more rows, 30 more variables: Hs6Code <chr>,
#> #   Hs6Description <chr>, Cn8Code <chr>, Cn8LongDescription <chr>,
#> #   Sitc1Code <chr>, Sitc1Desc <chr>, Sitc2Code <chr>, Sitc2Desc <chr>,
#> #   Sitc3Code <chr>, Sitc3Desc <chr>, Sitc4Code <chr>, Sitc4Desc <chr>,
#> #   Area1 <chr>, Area1a <chr>, Area2 <chr>, Area2a <chr>, Area3 <chr>,
#> #   Area3a <chr>, Area5a <chr>, CountryId <int>, CountryCodeNumeric <chr>,
#> #   CountryCodeAlpha <chr>, CountryName <chr>, PortId <int>, ...
```

Note that SITC codes need to be in character format, and include any
leading zeros. This is because, unlike HS or CN codes, odd SITC codes
exist (e.g. SITC1). We can also select a selection of codes in a similar
way to HS/CN codes:

``` r
data <- load_ots(month = 201901, country = "AU", flow = 4, sitc = c("0", "11"), join_lookup = TRUE)

data
#> # A tibble: 317 x 39
#>    MonthId FlowTypeId FlowType~1 Suppr~2 Suppr~3 Hs2Code Hs2De~4 Hs4Code Hs4De~5
#>      <int>      <int> <chr>        <dbl> <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1  201901          4 "Non-EU E~       0 <NA>    01      Live a~ 0101    Live h~
#>  2  201901          4 "Non-EU E~       0 <NA>    01      Live a~ 0101    Live h~
#>  3  201901          4 "Non-EU E~       0 <NA>    02      Meat a~ 0203    Meat o~
#>  4  201901          4 "Non-EU E~       0 <NA>    02      Meat a~ 0203    Meat o~
#>  5  201901          4 "Non-EU E~       0 <NA>    02      Meat a~ 0203    Meat o~
#>  6  201901          4 "Non-EU E~       0 <NA>    02      Meat a~ 0203    Meat o~
#>  7  201901          4 "Non-EU E~       0 <NA>    02      Meat a~ 0206    Edible~
#>  8  201901          4 "Non-EU E~       0 <NA>    03      Fish a~ 0304    Fish f~
#>  9  201901          4 "Non-EU E~       0 <NA>    03      Fish a~ 0305    Fish, ~
#> 10  201901          4 "Non-EU E~       0 <NA>    04      Dairy ~ 0402    Milk a~
#> # ... with 307 more rows, 30 more variables: Hs6Code <chr>,
#> #   Hs6Description <chr>, Cn8Code <chr>, Cn8LongDescription <chr>,
#> #   Sitc1Code <chr>, Sitc1Desc <chr>, Sitc2Code <chr>, Sitc2Desc <chr>,
#> #   Sitc3Code <chr>, Sitc3Desc <chr>, Sitc4Code <chr>, Sitc4Desc <chr>,
#> #   Area1 <chr>, Area1a <chr>, Area2 <chr>, Area2a <chr>, Area3 <chr>,
#> #   Area3a <chr>, Area5a <chr>, CountryId <int>, CountryCodeNumeric <chr>,
#> #   CountryCodeAlpha <chr>, CountryName <chr>, PortId <int>, ...
```

### RTS

Loading all UK regional trade of 2-digit SITC Divisions ‘00 - Live
animals other than animals of division 03’ to ‘11 - Beverages’ for 2019
is done by specifying `sitc = c(00, 11)` (leading zeros are removed).
This again specifies a range, similar to the `month` argument. This is
done to avoid URLs being too long.

``` r
data <- load_rts(month = c(201901, 201912), sitc = c(0, 11), join_lookup = TRUE)

data
#> # A tibble: 64,357 x 26
#>    MonthId FlowTypeId FlowType~1 Sitc1~2 Sitc1~3 Commo~4 Sitc2~5 Sitc2~6 GovRe~7
#>      <int>      <int> <chr>      <chr>   <chr>     <int> <chr>   <chr>     <int>
#>  1  201901          3 "Non-EU I~ 0       Food &~       0 00      Live a~       2
#>  2  201904          3 "Non-EU I~ 0       Food &~       0 00      Live a~       2
#>  3  201907          3 "Non-EU I~ 0       Food &~       0 00      Live a~       2
#>  4  201910          3 "Non-EU I~ 0       Food &~       0 00      Live a~       2
#>  5  201901          3 "Non-EU I~ 0       Food &~       0 00      Live a~       3
#>  6  201904          3 "Non-EU I~ 0       Food &~       0 00      Live a~       3
#>  7  201907          3 "Non-EU I~ 0       Food &~       0 00      Live a~       3
#>  8  201910          3 "Non-EU I~ 0       Food &~       0 00      Live a~       3
#>  9  201901          3 "Non-EU I~ 0       Food &~       0 00      Live a~       4
#> 10  201904          3 "Non-EU I~ 0       Food &~       0 00      Live a~       4
#> # ... with 64,347 more rows, 17 more variables: GovRegionCodeNumeric <chr>,
#> #   GovRegionGroupCodeAlpha <chr>, GovRegionName <chr>,
#> #   GovRegionGroupName <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>,
#> #   CountryCodeNumeric <chr>, CountryCodeAlpha <chr>, CountryName <chr>,
#> #   Value <dbl>, NetMass <dbl>, and abbreviated variable names
#> #   1: FlowTypeDescription, 2: Sitc1Code, 3: Sitc1Desc, ...
```

Note: where relevant, BTTA data is [included in RTS
data](https://www.gov.uk/government/statistics/overseas-trade-statistics-methodologies/regional-trade-in-goods-statistics-methodology)
as well.

## Example using trader data

*Trader code is a work in progress…*

## Example using a custom URL

This example uses the `load_custom()` function to replicate the example
given in the [API
documentation](https://www.uktradeinfo.com/api-documentation/) for
finding all traders that exported ‘Live horses (excl. pure-bred for
breeding)’ from the ‘CB8’ post code in 2019. This way of loading data is
possible, but will require more data manipulation after obtaining the
results. This function is also the workhorse (no pun intended) behind
the other functions.

``` r
data <- load_custom(endpoint = "Commodity", custom_search = "?$filter=Hs6Code eq '010129'&$expand=Exports($filter=MonthId ge 201901 and MonthId le 201912 and startswith(Trader/PostCode, 'CB8'); $expand=Trader)",
    output = "tibble")

data
#> # A tibble: 2 x 11
#>   CommodityId Cn8Code  Hs2Code Hs4Code Hs6Code Hs2Desc~1 Hs4De~2 Hs6De~3 SitcC~4
#>         <int> <chr>    <chr>   <chr>   <chr>   <chr>     <chr>   <chr>   <chr>  
#> 1     1012910 01012910 01      0101    010129  Live ani~ Live h~ Live h~ 00150  
#> 2     1012990 01012990 01      0101    010129  Live ani~ Live h~ Live h~ 00150  
#> # ... with 2 more variables: Cn8LongDescription <chr>, Exports <list>, and
#> #   abbreviated variable names 1: Hs2Description, 2: Hs4Description,
#> #   3: Hs6Description, 4: SitcCommodityCode
```

Note that the variables expanded in the API query, Exports and Trader,
both need to be expanded as they are contained in a nested <list>
column. When unnested using `tidyr::unnest()`, we can see the final
results. The second expanded variable (Trader) itself contains 8 columns
(which are TraderId, CompanyName, five Address columns, and PostCode).

``` r
tidyr::unnest(data, Exports, names_repair = "unique")
#> New names:
#> * `CommodityId` -> `CommodityId...1`
#> * `CommodityId` -> `CommodityId...12`
#> # A tibble: 27 x 14
#>    CommodityId~1 Cn8Code Hs2Code Hs4Code Hs6Code Hs2De~2 Hs4De~3 Hs6De~4 SitcC~5
#>            <int> <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  2       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  3       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  4       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  5       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  6       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  7       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  8       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#>  9       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#> 10       1012990 010129~ 01      0101    010129  Live a~ Live h~ Live h~ 00150  
#> # ... with 17 more rows, 5 more variables: Cn8LongDescription <chr>,
#> #   TraderId <int>, CommodityId...12 <int>, MonthId <int>, Trader <df[,8]>, and
#> #   abbreviated variable names 1: CommodityId...1, 2: Hs2Description,
#> #   3: Hs4Description, 4: Hs6Description, 5: SitcCommodityCode
```

## MIT License

You’re free to use this code and its associated documentation without
restriction. This includes both personal and commercial use. However,
there is no warranty provided or any liability on my part. See the
LICENSE file for more information.
