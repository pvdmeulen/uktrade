
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
```

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":[""],"name":["_rn_"],"type":[""],"align":["left"]},{"label":["CommodityId"],"name":[1],"type":["int"],"align":["right"]},{"label":["Cn8Code"],"name":[2],"type":["chr"],"align":["left"]},{"label":["Hs2Code"],"name":[3],"type":["chr"],"align":["left"]},{"label":["Hs4Code"],"name":[4],"type":["chr"],"align":["left"]},{"label":["Hs6Code"],"name":[5],"type":["chr"],"align":["left"]},{"label":["Hs2Description"],"name":[6],"type":["chr"],"align":["left"]},{"label":["Hs4Description"],"name":[7],"type":["chr"],"align":["left"]},{"label":["Hs6Description"],"name":[8],"type":["chr"],"align":["left"]},{"label":["SitcCommodityCode"],"name":[9],"type":["chr"],"align":["left"]},{"label":["Cn8LongDescription"],"name":[10],"type":["chr"],"align":["left"]},{"label":["Exports"],"name":[11],"type":["list"],"align":["right"]}],"data":[{"1":"1012910","2":"01012910","3":"01","4":"0101","5":"010129","6":"Live animals","7":"Live horses, asses, mules and hinnies","8":"Live horses (excl. pure-bred for breeding)","9":"00150","10":"Horses for slaughter","11":"<df[,0] [0 × 0]>","_rn_":"1"},{"1":"1012990","2":"01012990","3":"01","4":"0101","5":"010129","6":"Live animals","7":"Live horses, asses, mules and hinnies","8":"Live horses (excl. pure-bred for breeding)","9":"00150","10":"Live horses (excl. for slaughter, pure-bred for breeding)","11":"<df[,4] [27 × 4]>","_rn_":"2"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

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
