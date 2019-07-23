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
  #this could be done somewhere else maybe.. not sure.
  all_p %>% combinat::combn(.,2) %>% as_tibble(.,.name_repair="universal") -> pwise
    pwise[c(2,1),] %>% map_chr(.,~paste(.,collapse="vs")) %>% paste(.,collapse="|") -> unique_comparisons
  srates<-srates[,grepl(unique_comparisons,names(srates))]

  map(all_p[!(all_p %in% y)],
      ~srates[,grepl(paste0(fctr,".pop",.x),names(srates))]
  ) %>%
    map(.,~mutate_at(.,vars(matches(y)),~(-(length(all_p)-2)*.x))) %>%
    map(.,rowSums,na.rm=T) %>% as_tibble(.,.name_repair="universal") %>%
    mutate(
      sum2=rowSums(.,na.rm=T)/(length(all_p)*(length(all_p)-1)),
      sum1=rowSums(srates[,grepl(paste0(fctr,".pop",y),names(srates))],na.rm=T)/(length(all_p)-1),
      !!(paste0("pop",y)):=sum1+sum2
    ) %>% dplyr::select(!!paste0("pop",y))
}
