
<!-- README.md is generated from README.Rmd. Please edit that file -->

# uktrade

<!-- badges: start -->

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The goal of `uktrade` is to provide convenient wrapper functions for
analysing HMRC data in R.

## Installation

You can install the latest version of `uktrade` from this GitHub
repository using `remotes`:

``` r
remotes::install_github("pvdmeulen/uktrade")
```

## HMRC data

Her Majesty’s Revenue & Customs (HMRC) is the UK’s customs authority and
a non-ministerial department of the United Kingdom Government. Data on
UK trade is available on their
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
-   `load_rts()`: a function for loading Regional Trade Statistics data
-   `load_trader()`: a function for loading trader data
-   `load_custom()`: a function for loading a custom URL

All of these functions will output a `dataframe` object with the desired
data, and are able to keep track of paginated results (in batches of
30,000 rows) as well as the API request limit of 60 requests per minute.

## Example

This example uses the `load_custom()` function to replicate the example
given in the [API
documentation](https://www.uktradeinfo.com/api-documentation/) for
finding all traders that exported ‘Live horses (excl. pure-bred for
breeding)’ from the ‘CB8’ post code in 2019:

``` r
library(uktrade)

data <- load_custom(endpoint = "Commodity", custom_search = "?$filter=Hs6Code eq '010129'&$expand=Exports($filter=MonthId ge 201901 and MonthId le 201912 and startswith(Trader/PostCode, 'CB8'); $expand=Trader)")

head(data)
#> # A tibble: 2 x 11
#>   CommodityId Cn8Code  Hs2Code Hs4Code Hs6Code Hs2Description Hs4Description    
#>         <int> <chr>    <chr>   <chr>   <chr>   <chr>          <chr>             
#> 1     1012910 01012910 01      0101    010129  Live animals   Live horses, asse~
#> 2     1012990 01012990 01      0101    010129  Live animals   Live horses, asse~
#> # ... with 4 more variables: Hs6Description <chr>, SitcCommodityCode <chr>,
#> #   Cn8LongDescription <chr>, Exports <list>
```

## MIT License

You’re free to use this code and its associated documentation without
restriction. This includes both personal and commercial use. However,
there is no warranty provided or any liability on my part. See the
LICENSE file for more information.
