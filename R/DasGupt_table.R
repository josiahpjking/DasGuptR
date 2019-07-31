#' Das Gupta extract adjusted rates after
#' @param df DG output
#' @param pop1 population 1 (string or numeric)
#' @param pop2 population 2 (string or numeric)
#' @export
#' @examples
#' ......
DasGupt_table<-function(df,pop1,pop2){
  DasGupt_rates(df) %>% filter(population %in% c(pop1,pop2)) %>%
    spread(population,rate) %>%
    mutate(difference=get(paste0(pop1))-get(paste0(pop2)))
}
