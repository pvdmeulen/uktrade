
<!-- README.md is generated from README.Rmd. Please edit that file -->

# uktrade

<!-- badges: start -->

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/pvdmeulen/uktrade/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pvdmeulen/uktrade/actions/workflows/R-CMD-check.yaml)
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
data <- load_ots(month = c(201901, 201912), commodity = c(22083030, 22085011), join_lookup = FALSE, output = "tibble")

# Results are now in a tibble (set output to "df" to obtain a dataframe):
data
#> # A tibble: 4,663 × 10
#>    MonthId FlowTypeId SuppressionIndex CommodityId CommoditySitcId CountryId
#>      <int>      <int>            <int>       <int>           <int>     <int>
#>  1  201901          1                0    22083030           11241         1
#>  2  201902          1                0    22083030           11241         1
#>  3  201903          1                0    22083030           11241         1
#>  4  201904          1                0    22083030           11241         1
#>  5  201905          1                0    22083030           11241         1
#>  6  201906          1                0    22083030           11241         1
#>  7  201907          1                0    22083030           11241         1
#>  8  201908          1                0    22083030           11241         1
#>  9  201909          1                0    22083030           11241         1
#> 10  201910          1                0    22083030           11241         1
#> # ℹ 4,653 more rows
#> # ℹ 4 more variables: PortId <int>, Value <dbl>, NetMass <dbl>, SuppUnit <dbl>
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
#> # A tibble: 4,663 × 39
#>    MonthId FlowTypeId FlowTypeDescription       SuppressionIndex SuppressionDesc
#>      <int>      <int> <chr>                                <dbl> <chr>          
#>  1  201901          1 "EU Imports             …                0 <NA>           
#>  2  201902          1 "EU Imports             …                0 <NA>           
#>  3  201903          1 "EU Imports             …                0 <NA>           
#>  4  201904          1 "EU Imports             …                0 <NA>           
#>  5  201905          1 "EU Imports             …                0 <NA>           
#>  6  201906          1 "EU Imports             …                0 <NA>           
#>  7  201907          1 "EU Imports             …                0 <NA>           
#>  8  201908          1 "EU Imports             …                0 <NA>           
#>  9  201909          1 "EU Imports             …                0 <NA>           
#> 10  201910          1 "EU Imports             …                0 <NA>           
#> # ℹ 4,653 more rows
#> # ℹ 34 more variables: Hs2Code <chr>, Hs2Description <chr>, Hs4Code <chr>,
#> #   Hs4Description <chr>, Hs6Code <chr>, Hs6Description <chr>, Cn8Code <chr>,
#> #   Cn8LongDescription <chr>, Sitc1Code <chr>, Sitc1Desc <chr>,
#> #   Sitc2Code <chr>, Sitc2Desc <chr>, Sitc3Code <chr>, Sitc3Desc <chr>,
#> #   Sitc4Code <chr>, Sitc4Desc <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>, …
```

Loading aggregate data (such as all spirits, HS4 code 2208) is possible
too (in the background, this is loading commodity codes greater than or
equal to 22080000 and less than or equal to 22089999). You can also see
what URL the code is using by specifying `print_URL = TRUE`:

``` r
data <- load_ots(month = c(201901, 201912), commodity = 2208, join_lookup = TRUE, print_url = TRUE)
#> Loading data via the following URL(s):
#> URL 1: https://api.uktradeinfo.com/OTS?$filter=(MonthId ge 201901 and MonthId le 201912) and ((CommodityId ge 22080000 and CommodityId le 22089999))

data
#> # A tibble: 23,466 × 39
#>    MonthId FlowTypeId FlowTypeDescription       SuppressionIndex SuppressionDesc
#>      <int>      <int> <chr>                                <dbl> <chr>          
#>  1  201901          1 "EU Imports             …                0 <NA>           
#>  2  201902          1 "EU Imports             …                0 <NA>           
#>  3  201903          1 "EU Imports             …                0 <NA>           
#>  4  201904          1 "EU Imports             …                0 <NA>           
#>  5  201905          1 "EU Imports             …                0 <NA>           
#>  6  201906          1 "EU Imports             …                0 <NA>           
#>  7  201907          1 "EU Imports             …                0 <NA>           
#>  8  201908          1 "EU Imports             …                0 <NA>           
#>  9  201909          1 "EU Imports             …                0 <NA>           
#> 10  201910          1 "EU Imports             …                0 <NA>           
#> # ℹ 23,456 more rows
#> # ℹ 34 more variables: Hs2Code <chr>, Hs2Description <chr>, Hs4Code <chr>,
#> #   Hs4Description <chr>, Hs6Code <chr>, Hs6Description <chr>, Cn8Code <chr>,
#> #   Cn8LongDescription <chr>, Sitc1Code <chr>, Sitc1Desc <chr>,
#> #   Sitc2Code <chr>, Sitc2Desc <chr>, Sitc3Code <chr>, Sitc3Desc <chr>,
#> #   Sitc4Code <chr>, Sitc4Desc <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>, …
```

When loading an HS2 code, or a SITC1 or SITC2 code, so-called Below
Threshold Trade Allocation estimates are also loaded (for EU trade).
These are, roughly, estimated values for those trades which fell below
the Intrastat Survey threshold. At more detailed commodity levels, these
estimates are excluded. BTTA trade estimates have different commodity
codes (9-digit CN codes ending in 9999999, or 7-digit SITC codes ending
in 99999):

``` r
data <- load_ots(month = c(202101, 202103), commodity = "03", join_lookup = TRUE, print_url = TRUE)
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
#> # A tibble: 54 × 39
#>    MonthId FlowTypeId FlowTypeDescription       SuppressionIndex SuppressionDesc
#>      <int>      <int> <chr>                                <dbl> <chr>          
#>  1  202101          1 "EU Imports             …                0 <NA>           
#>  2  202101          2 "EU Exports             …                0 <NA>           
#>  3  202102          2 "EU Exports             …                0 <NA>           
#>  4  202103          2 "EU Exports             …                0 <NA>           
#>  5  202101          1 "EU Imports             …                0 <NA>           
#>  6  202102          1 "EU Imports             …                0 <NA>           
#>  7  202103          1 "EU Imports             …                0 <NA>           
#>  8  202101          2 "EU Exports             …                0 <NA>           
#>  9  202102          2 "EU Exports             …                0 <NA>           
#> 10  202103          2 "EU Exports             …                0 <NA>           
#> # ℹ 44 more rows
#> # ℹ 34 more variables: Hs2Code <chr>, Hs2Description <chr>, Hs4Code <chr>,
#> #   Hs4Description <chr>, Hs6Code <chr>, Hs6Description <chr>, Cn8Code <chr>,
#> #   Cn8LongDescription <chr>, Sitc1Code <chr>, Sitc1Desc <chr>,
#> #   Sitc2Code <chr>, Sitc2Desc <chr>, Sitc3Code <chr>, Sitc3Desc <chr>,
#> #   Sitc4Code <chr>, Sitc4Desc <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>, …
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
#> # A tibble: 4,960 × 39
#>    MonthId FlowTypeId FlowTypeDescription       SuppressionIndex SuppressionDesc
#>      <int>      <int> <chr>                                <dbl> <chr>          
#>  1  201901          4 "Non-EU Exports         …                0 <NA>           
#>  2  201901          4 "Non-EU Exports         …                0 <NA>           
#>  3  201901          4 "Non-EU Exports         …                0 <NA>           
#>  4  201901          4 "Non-EU Exports         …                0 <NA>           
#>  5  201901          4 "Non-EU Exports         …                0 <NA>           
#>  6  201901          4 "Non-EU Exports         …                0 <NA>           
#>  7  201901          4 "Non-EU Exports         …                0 <NA>           
#>  8  201901          4 "Non-EU Exports         …                0 <NA>           
#>  9  201901          4 "Non-EU Exports         …                0 <NA>           
#> 10  201901          4 "Non-EU Exports         …                0 <NA>           
#> # ℹ 4,950 more rows
#> # ℹ 34 more variables: Hs2Code <chr>, Hs2Description <chr>, Hs4Code <chr>,
#> #   Hs4Description <chr>, Hs6Code <chr>, Hs6Description <chr>, Cn8Code <chr>,
#> #   Cn8LongDescription <chr>, Sitc1Code <chr>, Sitc1Desc <chr>,
#> #   Sitc2Code <chr>, Sitc2Desc <chr>, Sitc3Code <chr>, Sitc3Desc <chr>,
#> #   Sitc4Code <chr>, Sitc4Desc <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>, …
```

We can also use SITC codes - here, we load all beverage (SITC2 code 11)
exports to Australia in January 2019:

``` r
data <- load_ots(month = 201901, country = "AU", flow = 4, sitc = "11", join_lookup = TRUE)

data
#> # A tibble: 105 × 39
#>    MonthId FlowTypeId FlowTypeDescription       SuppressionIndex SuppressionDesc
#>      <int>      <int> <chr>                                <dbl> <chr>          
#>  1  201901          4 "Non-EU Exports         …                0 <NA>           
#>  2  201901          4 "Non-EU Exports         …                0 <NA>           
#>  3  201901          4 "Non-EU Exports         …                0 <NA>           
#>  4  201901          4 "Non-EU Exports         …                0 <NA>           
#>  5  201901          4 "Non-EU Exports         …                0 <NA>           
#>  6  201901          4 "Non-EU Exports         …                0 <NA>           
#>  7  201901          4 "Non-EU Exports         …                0 <NA>           
#>  8  201901          4 "Non-EU Exports         …                0 <NA>           
#>  9  201901          4 "Non-EU Exports         …                0 <NA>           
#> 10  201901          4 "Non-EU Exports         …                0 <NA>           
#> # ℹ 95 more rows
#> # ℹ 34 more variables: Hs2Code <chr>, Hs2Description <chr>, Hs4Code <chr>,
#> #   Hs4Description <chr>, Hs6Code <chr>, Hs6Description <chr>, Cn8Code <chr>,
#> #   Cn8LongDescription <chr>, Sitc1Code <chr>, Sitc1Desc <chr>,
#> #   Sitc2Code <chr>, Sitc2Desc <chr>, Sitc3Code <chr>, Sitc3Desc <chr>,
#> #   Sitc4Code <chr>, Sitc4Desc <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>, …
```

Note that SITC codes need to be in character format, and include any
leading zeros. This is because, unlike HS or CN codes, odd SITC codes
exist (e.g. SITC1). We can also select a selection of codes in a similar
way to HS/CN codes:

``` r
data <- load_ots(month = 201901, country = "AU", flow = 4, sitc = c("0", "11"), join_lookup = TRUE)

data
#> # A tibble: 317 × 39
#>    MonthId FlowTypeId FlowTypeDescription       SuppressionIndex SuppressionDesc
#>      <int>      <int> <chr>                                <dbl> <chr>          
#>  1  201901          4 "Non-EU Exports         …                0 <NA>           
#>  2  201901          4 "Non-EU Exports         …                0 <NA>           
#>  3  201901          4 "Non-EU Exports         …                0 <NA>           
#>  4  201901          4 "Non-EU Exports         …                0 <NA>           
#>  5  201901          4 "Non-EU Exports         …                0 <NA>           
#>  6  201901          4 "Non-EU Exports         …                0 <NA>           
#>  7  201901          4 "Non-EU Exports         …                0 <NA>           
#>  8  201901          4 "Non-EU Exports         …                0 <NA>           
#>  9  201901          4 "Non-EU Exports         …                0 <NA>           
#> 10  201901          4 "Non-EU Exports         …                0 <NA>           
#> # ℹ 307 more rows
#> # ℹ 34 more variables: Hs2Code <chr>, Hs2Description <chr>, Hs4Code <chr>,
#> #   Hs4Description <chr>, Hs6Code <chr>, Hs6Description <chr>, Cn8Code <chr>,
#> #   Cn8LongDescription <chr>, Sitc1Code <chr>, Sitc1Desc <chr>,
#> #   Sitc2Code <chr>, Sitc2Desc <chr>, Sitc3Code <chr>, Sitc3Desc <chr>,
#> #   Sitc4Code <chr>, Sitc4Desc <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>, …
```

### RTS

Loading all UK regional trade of 2-digit SITC Divisions ‘00 - Live
animals other than animals of division 03’ to ‘11 - Beverages’ for 2019
is done by specifying `sitc = c(00, 11)` (leading zeros are removed).
This again specifies a range, similar to the `month` argument. This is
done to avoid URLs being too long.

``` r
data <- load_rts(month = c(201901, 201912), sitc = c(00, 11), join_lookup = TRUE)

data
#> # A tibble: 54,265 × 26
#>    MonthId FlowTypeId FlowTypeDescription   Sitc1Code Sitc1Desc CommoditySitc2Id
#>      <int>      <int> <chr>                 <chr>     <chr>                <int>
#>  1  201901          3 "Non-EU Imports     … 0         Food & l…                0
#>  2  201904          3 "Non-EU Imports     … 0         Food & l…                0
#>  3  201907          3 "Non-EU Imports     … 0         Food & l…                0
#>  4  201910          3 "Non-EU Imports     … 0         Food & l…                0
#>  5  201901          3 "Non-EU Imports     … 0         Food & l…                0
#>  6  201904          3 "Non-EU Imports     … 0         Food & l…                0
#>  7  201907          3 "Non-EU Imports     … 0         Food & l…                0
#>  8  201910          3 "Non-EU Imports     … 0         Food & l…                0
#>  9  201901          3 "Non-EU Imports     … 0         Food & l…                0
#> 10  201904          3 "Non-EU Imports     … 0         Food & l…                0
#> # ℹ 54,255 more rows
#> # ℹ 20 more variables: Sitc2Code <chr>, Sitc2Desc <chr>, GovRegionId <int>,
#> #   GovRegionCodeNumeric <chr>, GovRegionGroupCodeAlpha <chr>,
#> #   GovRegionName <chr>, GovRegionGroupName <chr>, Area1 <chr>, Area1a <chr>,
#> #   Area2 <chr>, Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>,
#> #   CountryId <int>, CountryCodeNumeric <chr>, CountryCodeAlpha <chr>,
#> #   CountryName <chr>, Value <dbl>, NetMass <dbl>
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
data <- load_custom(endpoint = "Commodity", custom_search = "?$filter=Hs6Code eq '010129'&$expand=Exports($filter=MonthId ge 201901 and MonthId le 201912 and startswith(Trader/PostCode, 'CB8'); $expand=Trader)", output = "tibble")

data
#> # A tibble: 2 × 11
#>   CommodityId Cn8Code  Hs2Code Hs4Code Hs6Code Hs2Description Hs4Description    
#>         <int> <chr>    <chr>   <chr>   <chr>   <chr>          <chr>             
#> 1     1012910 01012910 01      0101    010129  Live animals   Live horses, asse…
#> 2     1012990 01012990 01      0101    010129  Live animals   Live horses, asse…
#> # ℹ 4 more variables: Hs6Description <chr>, SitcCommodityCode <chr>,
#> #   Cn8LongDescription <chr>, Exports <list>
```

Note that the variables expanded in the API query, Exports and Trader,
both need to be expanded as they are contained in a nested <list>
column. When unnested using `tidyr::unnest()`, we can see the final
results. The second expanded variable (Trader) itself contains 8 columns
(which are TraderId, CompanyName, five Address columns, and PostCode).

``` r
tidyr::unnest(data, Exports, names_repair = "unique")
#> New names:
#> • `CommodityId` -> `CommodityId...1`
#> • `CommodityId` -> `CommodityId...12`
#> # A tibble: 27 × 14
#>    CommodityId...1 Cn8Code Hs2Code Hs4Code Hs6Code Hs2Description Hs4Description
#>              <int> <chr>   <chr>   <chr>   <chr>   <chr>          <chr>         
#>  1         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  2         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  3         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  4         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  5         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  6         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  7         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  8         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#>  9         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#> 10         1012990 010129… 01      0101    010129  Live animals   Live horses, …
#> # ℹ 17 more rows
#> # ℹ 7 more variables: Hs6Description <chr>, SitcCommodityCode <chr>,
#> #   Cn8LongDescription <chr>, TraderId <int>, CommodityId...12 <int>,
#> #   MonthId <int>, Trader <df[,8]>
```

## MIT License

You’re free to use this code and its associated documentation without
restriction. This includes both personal and commercial use. However,
there is no warranty provided or any liability on my part. See the
LICENSE file for more information.
