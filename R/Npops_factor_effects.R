#' The full Das Gupta 6.12 equation for a factor-effect between 2 populations
#' Outputs a tibble object specifying the factor-effect standardised across all populations
#' @param factoreffs a dataframe/tibble object of ?? can't remember!!!
#' @param ps vector of length 2 specifying a possible pairwise comparison of populations
#' @param all_p character or numeric vector of all N populations
#' @export
#' @examples
#' ......
Npops_factor_effects<-function(factoreffs,ps,all_p){
  y1<-ps[1]
  y2<-ps[2]
  #all_y=pws_pops %>% unlist %>% unique
  map_dfc(all_p[!(all_p %in% c(y1,y2))],~DG612numerator(factoreffs,y1,y2,.)) %>%
    tibble(
      dg612=rowSums(.,na.rm=T)/length(all_p),
      a12=factoreffs[,grepl(paste0(y1,"vs",y2),names(factoreffs))] %>% unlist %>% unname,
      !!paste0("diff",y1,"_",y2):=a12-dg612
    ) %>% select(paste0("diff",y1,"_",y2))
}
