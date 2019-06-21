# DasGuptR
decomposition and standardisation of rates by Das Gupta's 1991 methods.

devtools::install_github("josiahpjking/DasGuptR")
library(tidyverse)
library(matrixStats)
library(combinat)
library(DasGuptR)

library(conflicted)
conflict_prefer("filter", "dplyr")

# 2 pops!
dg2pops <- DasGupt_2pop(testdf,year,c("prev","age_str","freq","disposal_prop","crime_type_prop"))

# N pops!
dgtimeseries <- DasGupt_Npop(testdf3,pop=year,prev,age_str,freq,disposal_prop,crime_type_prop)

#get the prev factor diffs
dgtimeseries$prev$factor_effects
#or standardised rates
dgtimeseries$prev$standardised_rates

