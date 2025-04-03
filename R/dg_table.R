#' Creates a small table of Das Gupta standardised rates. If no populations are specified, rates will be shown for all available populations. If only two populations (or if two particular populations are specified), then rate-differences and 'decomposition effects' are calculated and presented.
#' @param dgo output from `dgnpop()`
#' @param pop1 optional name of first population for decomposition (character/numeric)
#' @param pop2 optional name of second population for decomposition (character/numeric)
#' @return data.frame object with rows for each of the K-a standardised rates and the crude rates, and columns for each of the N populations. When only two populations are included, or if two populations are explicitly specified, standardised rate differences are provided, and are also expressed as a percentage of the crude rate differences (typically referred to as 'decomposition effects').
#' @export
dg_table <- function(dgo, pop1 = NULL, pop2 = NULL) {
  # n pops
  npops <- length(unique(dgo[["pop"]]))
  # make crude go last
  factors <- unique(dgo[["factor"]])
  factor_levels <- c(setdiff(factors, "crude"), "crude")
  dgo$factor <- factor(dgo$factor, levels = factor_levels)

  if (is.null(pop1) & is.null(pop2)) {
    if (npops > 2) {
      dgt <- as.data.frame.matrix(xtabs(rate ~ factor + pop, dgo))
    } else {
      dgt <- as.data.frame.matrix(
        addmargins(xtabs(rate ~ factor + pop, dgo),
                   margin = 2, FUN = diff
        )
      )
      dgt$decomp <- round(dgt[["diff"]] / dgt[row.names(dgt) == "crude", "diff"] * 100, 2)
    }
  } else {
    dgt <- as.data.frame.matrix(
      addmargins(xtabs(rate ~ factor + pop, droplevels(dgo[dgo[["pop"]] %in% c(pop1, pop2), ])),
                 margin = 2, FUN = diff
      )
    )
    dgt$decomp <- round(dgt[["diff"]] / dgt[row.names(dgt) == "crude", "diff"] * 100, 2)
  }
  return(dgt)
}
