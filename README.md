
<!-- README.md is generated from README.Rmd. Please edit that file -->

# uktrade

<!-- badges: start -->

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The goal of uktrade is to provide convenient wrapper functions for
analysing HMRC data in R.

## Installation

You can install the released version of uktrade from this GitHub
repository using `remotes`:

``` r
remotes::install_github()
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
This update also introduced an
[API](https://www.uktradeinfo.com/api-documentation/) (Application
Programming Interface) for accessing bulk trade (and trader) data. For
smaller trade data extracts (&lt; 30,000 rows), the [online
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

``` r
library(uktrade)
## basic example code
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
