#' The full Das Gupta 6.12 equation for a factor-effect between 2 populations when standardised across N populations.
#' Outputs a dataframe object specifying the factor-effect standardised across all populations
#' @param srates a dataframe output from dg2p
#' @param all_p character or numeric vector of all N populations
#' @param ps vector of length 2 specifying a possible pairwise comparison of populations
#' @param factor character string indicating name of factor
#' @export
dg612<-function(srates, all_p, ps, factor){

  n = length(all_p)
  y1 = ps[1]
  y2 = ps[2]

  eq.612.a = srates[srates$pop == y1 & srates$std.set == y2, "diff"]

  # eq.612.a = srates[srates$pop == y2 & srates$std.set == y1, 'rate'] -
  #   srates[srates$pop == y1 & srates$std.set == y2, 'rate'])



  eq.612.b = sum(
    sapply(all_p[!all_p %in% c(y1,y2)], \(yy)
         # a_12
         eq.612.a +
           # a_2j
           srates[srates$pop == y2 & srates$std.set == yy, "diff"] -
           # -a_1j
           srates[srates$pop == y1 & srates$std.set == yy, "diff"]
    )
  ) / n

  res = data.frame(
    diff = eq.612.a - eq.612.b,
    pop = y1,
    diff.calc = paste0(y1,"-",y2),
    std.set = paste0(all_p[!all_p %in% c(y1,y2)], collapse="."),
    factor = factor
  )

  return(res)
}
