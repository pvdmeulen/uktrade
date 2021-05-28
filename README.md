
<!-- README.md is generated from README.Rmd. Please edit that file -->

# uktrade

<!-- badges: start -->

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The goal of `uktrade` is to provide convenient wrapper functions for
loading HMRC data in R.

## Installation

You can install the latest version of `uktrade` from this GitHub
repository using `remotes`:

``` r
remotes::install_github("pvdmeulen/uktrade")
```

## HMRC data

Her Majesty’s Revenue & Customs (HMRC) is the UK’s customs authority.
Data on UK trade is available on their
[uktradeinfo.com](https://www.uktradeinfo.com/) website, which is
collected through a combination of customs declarations and Intrastat
surveys (in the case of [some EU trade](https://www.gov.uk/intrastat)).

In the beginning of 2021, the
[uktradeinfo.com](https://www.uktradeinfo.com/) website was updated.
This update also introduced an Application Programming Interface (API)
for accessing bulk trade (and trader) data. For smaller trade data
extracts (&lt; 30,000 rows), the [online
tool](https://www.uktradeinfo.com/trade-data/) may be sufficient.

## This package

This package contains four functions:

-   `load_ots()`: a function for loading Overseas Trade Statistics data
    (work in progress)
-   `load_rts()`: a function for loading Regional Trade Statistics data
    (future work)
-   `load_trader()`: a function for loading trader data (future work)
-   `load_custom()`: a function for loading a custom URL (work in
    progress)

All of these functions will output a `dataframe` object with the desired
data, and are able to keep track of paginated results (in batches of
30,000 rows) as well as the API request limit of 60 requests per minute.

The first three are convenient wrapper functions which should make
loading the majority of data people are after easier (with the
assumption that further data manipulation will be done in R after
loading the data). Of course, the API allows for extensive customisation
in what data is obtained. For this purpose, `load_custom()` allows you
to specify a custom URL instead. This allows you to be more specific
right in your request (and in the case of trader data, expand specific
columns to get more information).

## Example using OTS and RTS data

These functions are convenient wrappers for loading trade data - either
UK trade data using OTS, or regional UK trade data using RTS. These
functions will load the raw data and join results with lookups obtained
from the API (using, for example, the /Commodity and /Country
endpoints). This makes data easy to read by humans, but also larger
(more text). Disabling the lookup join is possible by setting
`join_lookup = FALSE` in these functions.

### OTS

Loading all UK trade of single malt Scotch whisky (CN8 code 22083030)
and bottled gin (22085011) for 2019 is done like so:

``` r
library(uktrade)
data <- load_ots(month = 201901:201912, commodity = c(22083030, 22085011), join_lookup = FALSE)

# Results are now in a tibble:
data
#> # A tibble: 4,663 x 10
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
#> # ... with 4,653 more rows, and 4 more variables: PortId <int>, Value <dbl>,
#> #   NetMass <dbl>, SuppUnit <dbl>
```

As you can see, results are not easily interpretable as they stand. The
HMRC API also has lookups which can be loaded separately using
`load_custom()`, or joined automatically:

``` r
library(uktrade)
data <- load_ots(month = 201901:201912, commodity = c(22083030, 22085011), join_lookup = TRUE)
#> Warning: package 'dplyr' was built under R version 4.0.5
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

data
#> # A tibble: 4,663 x 36
#>    MonthId FlowTypeId FlowTypeDescript~ SuppressionIndex SuppressionDesc Hs2Code
#>      <int>      <int> <chr>                        <dbl> <chr>           <chr>  
#>  1  201901          1 "EU Imports     ~                0 <NA>            22     
#>  2  201902          1 "EU Imports     ~                0 <NA>            22     
#>  3  201903          1 "EU Imports     ~                0 <NA>            22     
#>  4  201904          1 "EU Imports     ~                0 <NA>            22     
#>  5  201905          1 "EU Imports     ~                0 <NA>            22     
#>  6  201906          1 "EU Imports     ~                0 <NA>            22     
#>  7  201907          1 "EU Imports     ~                0 <NA>            22     
#>  8  201908          1 "EU Imports     ~                0 <NA>            22     
#>  9  201909          1 "EU Imports     ~                0 <NA>            22     
#> 10  201910          1 "EU Imports     ~                0 <NA>            22     
#> # ... with 4,653 more rows, and 30 more variables: Hs2Description <chr>,
#> #   Hs4Code <chr>, Hs4Description <chr>, Hs6Code <chr>, Hs6Description <chr>,
#> #   Cn8Code <chr>, Cn8LongDescription <chr>, Sitc1Code <chr>, Sitc1Desc <chr>,
#> #   Sitc2Code <chr>, Sitc2Desc <chr>, Sitc3Code <chr>, Sitc3Desc <chr>,
#> #   Sitc4Code <chr>, Sitc4Desc <chr>, Area1 <chr>, Area1a <chr>, Area2 <chr>,
#> #   Area2a <chr>, Area3 <chr>, Area3a <chr>, Area5a <chr>, CountryId <int>,
#> #   CountryCodeNumeric <chr>, CountryCodeAlpha <chr>, CountryName <chr>,
#> #   PortId <int>, PortCodeNumeric <chr>, PortCodeAlpha <chr>, PortName <chr>
```

Note that HMRC’s API isn’t working entirely as expected at the moment.
At the moment, loading aggregate data (such as all spirits, HS4 code
2208) returns an empty dataframe:

``` r
library(uktrade)
data <- load_ots(month = 201901:201912, commodity = 2208, join_lookup = FALSE)

data
#> # A tibble: 0 x 0
```

Specifying `commodity = 0` will load all commodities aggregated
(specifying `NULL` will load all detailed commodities and may take
considerable time):

``` r
library(uktrade)
data <- load_ots(month = 201901, commodity = 0, join_lookup = FALSE)

data
#> # A tibble: 136 x 10
#>    MonthId FlowTypeId SuppressionIndex CommodityId CommoditySitcId CountryId
#>      <int>      <int>            <int>       <int>           <int>     <int>
#>  1  201901          1                0           0            -990       959
#>  2  201901          2                0           0            -990       959
#>  3  201901          1                0           0            -980       959
#>  4  201901          2                0           0            -980       959
#>  5  201901          1                0           0            -970       959
#>  6  201901          2                0           0            -970       959
#>  7  201901          1                0           0            -960       959
#>  8  201901          2                0           0            -960       959
#>  9  201901          1                0           0            -930       959
#> 10  201901          2                0           0            -930       959
#> # ... with 126 more rows, and 4 more variables: PortId <int>, Value <dbl>,
#> #   NetMass <lgl>, SuppUnit <lgl>
```

### RTS

RTS code is a work in progress…

## Example using trader data

Trader code is a work in progress…

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
library(uktrade)
data <- load_custom(endpoint = "Commodity", custom_search = "?$filter=Hs6Code eq '010129'&$expand=Exports($filter=MonthId ge 201901 and MonthId le 201912 and startswith(Trader/PostCode, 'CB8'); $expand=Trader)", 
    output = "tibble")

data
#> # A tibble: 2 x 11
#>   CommodityId Cn8Code  Hs2Code Hs4Code Hs6Code Hs2Description Hs4Description    
#>         <int> <chr>    <chr>   <chr>   <chr>   <chr>          <chr>             
#> 1     1012910 01012910 01      0101    010129  Live animals   Live horses, asse~
#> 2     1012990 01012990 01      0101    010129  Live animals   Live horses, asse~
#> # ... with 4 more variables: Hs6Description <chr>, SitcCommodityCode <chr>,
#> #   Cn8LongDescription <chr>, Exports <list>
```

``` r
# Note that the first expanded column, Exports, is in a nested <list> format.
# When unnested using tidyr::unnest(), we can see the final results.  Note also
# that the second expanded column, Trader, contains 8 columns (which are
# TraderId, CompanyName, five Address columns, and PostCode).

library(tidyr)
tidyr::unnest(data, Exports, names_repair = "unique")
#> New names:
#> * CommodityId -> CommodityId...1
#> * CommodityId -> CommodityId...12
#> # A tibble: 27 x 14
#>    CommodityId...1 Cn8Code Hs2Code Hs4Code Hs6Code Hs2Description Hs4Description
#>              <int> <chr>   <chr>   <chr>   <chr>   <chr>          <chr>         
#>  1         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  2         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  3         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  4         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  5         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  6         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  7         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  8         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#>  9         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#> 10         1012990 010129~ 01      0101    010129  Live animals   Live horses, ~
#> # ... with 17 more rows, and 7 more variables: Hs6Description <chr>,
#> #   SitcCommodityCode <chr>, Cn8LongDescription <chr>, TraderId <int>,
#> #   CommodityId...12 <int>, MonthId <int>, Trader <df[,8]>
```

## MIT License

You’re free to use this code and its associated documentation without
restriction. This includes both personal and commercial use. However,
there is no warranty provided or any liability on my part. See the
LICENSE file for more information.
