#' Creates a small table of Das Gupta adjusted rates. If no populations are specified, rates will be shown for all available populations. If only two populations (or if two particular populations are specified), then difference effects are calculated and presented.
#' @param dgo DG output
#' @param pop1 population 1 (character/numeric)
#' @param pop2 population 2 (character/numeric)
#' @export
dg_table<-function(dgo,pop1=NULL,pop2=NULL){
  # n pops
  npops = length(unique(dgo[['pop']]))
  # make crude go last
  factors = unique(dgo[['factor']])
  factor_levels = c(setdiff(factors, "crude"), "crude")
  dgo$factor = factor(dgo$factor, levels = factor_levels)

  if(is.null(pop1) & is.null(pop2)){
    if(npops>2){
      dgt <- xtabs(rate ~ factor + pop, dgo) |>
        as.data.frame.matrix()
    }else{
      dgt <- xtabs(rate ~ factor + pop, dgo) |>
        addmargins(margin = 2, FUN = diff) |>
          as.data.frame.matrix()
      dgt$decomp <- round(dgt[['diff']]/dgt[row.names(dgt)=="crude",'diff']*100,2)
    }
  }else{
    dgt <- droplevels(dgo[dgo[["pop"]] %in% c(pop1, pop2), ]) |>
      xtabs(rate ~ factor + pop, data = _) |>
        addmargins(margin = 2, FUN = diff) |>
          as.data.frame.matrix()
    dgt$decomp <- round(dgt[['diff']]/dgt[row.names(dgt)=="crude",'diff']*100,2)
  }
  return(dgt)

}
