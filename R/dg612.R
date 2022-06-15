#' The full Das Gupta 6.12 equation for a factor-effect between 2 populations
#' Outputs a tibble object specifying the factor-effect standardised across all populations
#' @param factoreffs a dataframe/tibble object of ?? can't remember!!!
#' @param ps vector of length 2 specifying a possible pairwise comparison of populations
#' @param all_p character or numeric vector of all N populations
#' @export
#' @examples
#' ......
dg612<-function(factoreffs2, all_p, ps, fctr){
  #print(paste0("adjusting decomposition effects for N pops: ",paste(ps,collapse="vs")))

  # factoreffs = dg2p_facteffs
  # factoreffs2 = dg2p_facteffs2
  # ps = letters[1:2]
  # all_p = letters[1:3]
  # fctr = "facta"

  n = length(all_p)
  y1 = ps[1]
  y2 = ps[2]

  eq.612.a = factoreffs2$value[grepl(paste0("diff_",paste0(ps,collapse="")), factoreffs2$name)]

  eq.612.b = c(
    # a_12
    rep(eq.612.a, n-2),
    # a_2j
    factoreffs2$value[!grepl(paste0("diff_",y1), factoreffs2$name)],
    # -a_1j
    -1*factoreffs2$value[grepl(paste0("diff_",y1), factoreffs2$name) & !grepl(paste0("diff_",paste0(ps,collapse="")), factoreffs2$name)]
  )

  res = as.data.frame(eq.612.a + mean(eq.612.b))
  names(res) = paste0("factor_",fctr,".diff_",paste0(ps,collapse=""),".adj",paste0(all_p[!(all_p %in% ps)],collapse=""))

  return(res)
}
