#' Das Gupta equation 6.11: Standardises rates across populations
#' Outputs a tibble object of the rate factor F in population Y, standardised across all populations
#' @param srates a dataframe/tibble object of ?? can't remember!!!
#' @param all_p character or numeric vector of all N populations
#' @param y character of numeric value indicating a single population
#' @param fctr string indicating rate-factor being standardised.
#' @export
#' @examples
#' ......
Npops_std_rates<-function(srates,all_p,y,fctr){
  map(all_p[!(all_p %in% y)],
      ~srates[,grepl(paste0(fctr,".pop",.x),names(srates))]
  ) %>%
    map(.,~mutate_at(.,vars(matches(y)),~(-(length(all_p)-2)*.x))) %>%
    map(.,rowSums) %>% as_tibble(.,.name_repair="universal") %>%
    mutate(
      sum2=rowSums(.)/(length(all_p)*(length(all_p)-1)),
      sum1=rowSums(srates[,grepl(paste0(fctr,".pop",y),names(srates))])/(length(all_p)-1),
      !!(paste0("pop",y)):=sum1+sum2
    ) %>% select(!!paste0("pop",y))
}



# all_p = allpops
# fctr="prev"
# y="2011"
# srates = dg2p_rates
#
# map(all_p[!(all_p %in% y)],
#     ~srates[,grepl(paste0(fctr,".pop",.x),names(srates))]
# ) %>%
#   map(.,~mutate_at(.,vars(matches(y)),~(-(length(all_p)-2)*.x))) %>%
#   map(.,rowSums) %>% as_tibble(.,.name_repair="universal") %>%
#   mutate(
#     sum2=rowSums(.)/length(srates),
#     sum1=rowSums(srates[,grepl(paste0(fctr,".pop",y),names(srates))])/sum(grepl(paste0(fctr,".pop",y),names(srates))),
#     !!(paste0("pop",y)):=sum1+sum2
#   ) %>% select(!!paste0("pop",y))
# #
#
