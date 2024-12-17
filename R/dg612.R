#' The full Das Gupta 6.12 equation for a factor-effect between 2 populations
#' Outputs a tibble object specifying the factor-effect standardised across all populations
#' @param srates a dataframe output from dg2p
#' @param all_p character or numeric vector of all N populations
#' @param ps vector of length 2 specifying a possible pairwise comparison of populations
#' @export
#' @examples
#' ......
dg612<-function(srates, all_p, ps, factor){

  n = length(all_p)
  y1 = ps[1]
  y2 = ps[2]

  # eq.612.a = factoreffs$value[grepl(paste0("diff_",paste0(ps,collapse="")), factoreffs$name)]

  eq.612.a = srates[srates$pop == y1 & srates$adj.set == y2, "diff"]

  eq.612.b = sum(
    sapply(all_p[!all_p %in% c(y1,y2)], \(yy)
         # a_12
         eq.612.a +
           # a_2j
           srates[srates$pop == y2 & srates$adj.set != yy, "diff"] -
           # -a_1j
           srates[srates$pop == y1 & srates$adj.set != yy, "diff"]
    )
  ) / n

  res = data.frame(
    diff = eq.612.a - eq.612.b,
    pop = y1,
    diff.calc = paste0(y1,"-",y2),
    adj.set = paste0(all_p[!all_p %in% c(y1,y2)], collapse="."),
    factor = factor
  )

  return(res)
}
