#' Creates a small table of Das Gupta extract adjusted rates & difference effects for 2 specified populations.
#' @param df DG output
#' @param pop1 population 1 (character/numeric)
#' @param pop2 population 2 (character/numeric)
#' @export
dg_table<-function(df,pop1,pop2){
  dgr = dg_rates(df)
  dgr = dgr[dgr$pop %in% c(as.character(pop1), as.character(pop2)),]
  dgt = xtabs(adj.rate ~ factor + pop, droplevels(dgr))
  addmargins(dgt, margin = 2, FUN = diff)
}
