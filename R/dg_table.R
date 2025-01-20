#' Creates a small table of Das Gupta extract adjusted rates & difference effects for 2 specified populations.
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
      xtabs(rate ~ factor + pop, dgo)
    }else{
      xtabs(rate ~ factor + pop, dgo) |>
        addmargins(margin = 2, FUN = diff)
    }
  }else{
    droplevels(dgo[dgo[["pop"]] %in% c(pop1, pop2), ]) |>
      xtabs(rate ~ factor + pop, data = _) |>
        addmargins(margin = 2, FUN = diff)
  }
}
