
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
#>   CommodityId  Cn8Code Hs2Code Hs4Code Hs6Code Hs2Description
#> 1     1012910 01012910      01    0101  010129   Live animals
#> 2     1012990 01012990      01    0101  010129   Live animals
#>                          Hs4Description
#> 1 Live horses, asses, mules and hinnies
#> 2 Live horses, asses, mules and hinnies
#>                               Hs6Description SitcCommodityCode
#> 1 Live horses (excl. pure-bred for breeding)             00150
#> 2 Live horses (excl. pure-bred for breeding)             00150
#>                                          Cn8LongDescription
#> 1                                      Horses for slaughter
#> 2 Live horses (excl. for slaughter, pure-bred for breeding)
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    Exports
#> 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     NULL
#> 2 165616, 78423, 132859, 50485, 50485, 50485, 50485, 50485, 50485, 50485, 50485, 137089, 34152, 34152, 34152, 34152, 34152, 216120, 216120, 216120, 216120, 216120, 216120, 216120, 216120, 216120, 216120, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 1012990, 201909, 201909, 201911, 201903, 201905, 201907, 201908, 201909, 201910, 201911, 201912, 201912, 201903, 201905, 201910, 201911, 201912, 201901, 201903, 201904, 201905, 201907, 201908, 201909, 201910, 201911, 201912, 165616, 78423, 132859, 50485, 50485, 50485, 50485, 50485, 50485, 50485, 50485, 137089, 34152, 34152, 34152, 34152, 34152, 216120, 216120, 216120, 216120, 216120, 216120, 216120, 216120, 216120, 216120, FAWZI ABDULLA NASS, VARIAN STABLE LTD, COWELL FARMS, TATTERSALLS LTD, TATTERSALLS LTD, TATTERSALLS LTD, TATTERSALLS LTD, TATTERSALLS LTD, TATTERSALLS LTD, TATTERSALLS LTD, TATTERSALLS LTD, JUDDMONTE FARMS LIMITED, JANAH MANAGEMENT COMPANY LTD, JANAH MANAGEMENT COMPANY LTD, JANAH MANAGEMENT COMPANY LTD, JANAH MANAGEMENT COMPANY LTD, JANAH MANAGEMENT COMPANY LTD, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, BBA SHIPPING & TRANSPORT LIMITED, AISLABIE STUD, 49 BURY ROAD, HEATH HOUSE, TERRACE HOUSE, TERRACE HOUSE, TERRACE HOUSE, TERRACE HOUSE, TERRACE HOUSE, TERRACE HOUSE, TERRACE HOUSE, TERRACE HOUSE, BANSTEAD MANOR STUD, JANAH OFFICE, JANAH OFFICE, JANAH OFFICE, JANAH OFFICE, JANAH OFFICE, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, QUEENSBERRY MEWS, LEY ROAD, NEWMARKET, BOTTISHAM HEATH STUD, 125 HIGH STREET, 125 HIGH STREET, 125 HIGH STREET, 125 HIGH STREET, 125 HIGH STREET, 125 HIGH STREET, 125 HIGH STREET, 125 HIGH STREET, CHEVELEY, DALHAM HALL STUD, DALHAM HALL STUD, DALHAM HALL STUD, DALHAM HALL STUD, DALHAM HALL STUD, HIGH STREET, HIGH STREET, HIGH STREET, HIGH STREET, HIGH STREET, HIGH STREET, HIGH STREET, HIGH STREET, HIGH STREET, HIGH STREET, STETCHWORTH, SUFFOLK, SIX MILE BOTTOM, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, DUCHESS DRIVE, DUCHESS DRIVE, DUCHESS DRIVE, DUCHESS DRIVE, DUCHESS DRIVE, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, , NEWMARKET, SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, NEWMARKET, , , , , , , , , , , SUFFOLK, , SUFFOLK, , , , , , , , , , SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, SUFFOLK, , , , , , , , , , , CB8 9TS, CB8 7BY, CB8 0TT, CB8 9BT, CB8 9BT, CB8 9BT, CB8 9BT, CB8 9BT, CB8 9BT, CB8 9BT, CB8 9BT, CB8 9RD, CB8 9HE, CB8 9HE, CB8 9HE, CB8 9HE, CB8 9HE, CB8 9AE, CB8 9AE, CB8 9AE, CB8 9AE, CB8 9AE, CB8 9AE, CB8 9AE, CB8 9AE, CB8 9AE, CB8 9AE
```

What is special about using `README.Rmd` instead of just `README.md`?
You can include R chunks like so:

``` r
summary(cars)
#>      speed           dist       
#>  Min.   : 4.0   Min.   :  2.00  
#>  1st Qu.:12.0   1st Qu.: 26.00  
#>  Median :15.0   Median : 36.00  
#>  Mean   :15.4   Mean   : 42.98  
#>  3rd Qu.:19.0   3rd Qu.: 56.00  
#>  Max.   :25.0   Max.   :120.00
```

You’ll still need to render `README.Rmd` regularly, to keep `README.md`
up-to-date. `devtools::build_readme()` is handy for this. You could also
use GitHub Actions to re-render `README.Rmd` every time you push. An
example workflow can be found here:
<https://github.com/r-lib/actions/tree/master/examples>.

You can also embed plots, for example:

<img src="man/figures/README-pressure-1.png" width="100%" />

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub and CRAN.

## MIT License

You’re free to use this code and its associated documentation without
restriction. This includes both personal and commercial use. However,
there is no warranty provided or any liability on my part. See the
LICENSE file for more information.
