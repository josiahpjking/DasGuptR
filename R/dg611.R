#' Das Gupta equation 6.11: Standardises rates across populations
#' Outputs a tibble object of the rate factor F in population Y, standardised across all populations
#' @param srates2 a dataframe/tibble object of standardised rates from dg2pop
#' @param all_p character or numeric vector of all N populations
#' @param y character of numeric value indicating a single population
#' @param fctr string indicating rate-factor being standardised.
#' @export
#' @examples
#' ......
dg611<-function(srates2,all_p,y,fctr){

  # srates2=dg2p_rates2
  # factrs = c("prevalence","pop_str")
  # id_vars = c("Age","Sex")
  # ratefunction ="prevalence*pop_str"
  # all_p = pull(tmpdf,pop) %>% unique
  # fctr="pop_str"
  # y = all_p[1]


  srates2 = srates2[grepl(paste0(fctr), srates2$name), ]
  n = length(all_p)

  # EQ 6.11
  eq6.11.a = mean(srates2$value[grepl(paste0("pop_",y), srates2$name)])

  eq6.11.b = sum(c(
    srates2$value[!(grepl(paste0("pop_",y), srates2$name) | grepl(paste0(".adj",y), srates2$name) )],
    -(n-2)*srates2$value[grepl(paste0(".adj",y),srates2$name)]
  )) / (n*(n-1))

  res = as.data.frame(eq6.11.a + eq6.11.b)
  names(res) = paste0("factor_",fctr,".pop_",y,".adj",paste0(all_p[!(all_p %in% y)],collapse=""))

  return(res)
}
