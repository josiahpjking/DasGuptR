#' Creates a small table of Das Gupta extract adjusted rates & difference effects for 2 specified populations.
#' @param df DG output
#' @param pop1 population 1 (string or numeric)
#' @param pop2 population 2 (string or numeric)
#' @export
dg_table<-function(df,pop1,pop2){
  dg_rates(df) %>% filter(population %in% c(pop1,pop2)) %>%
    spread(population,rate) %>%
    mutate(difference=get(paste0(pop1))-get(paste0(pop2)))
}
