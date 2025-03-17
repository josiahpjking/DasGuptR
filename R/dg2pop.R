#' Standardisation and decomposition of rates over P rate-factors and 2 populations.
#' We suggest using dgnpop, which will internally call this function.
#' @param pw dataframe containing two populations worth of factor data, with columns specifying 1) population and 2) each rate-factor to be considered. must have column named "pop" indicating the population ID.
#' @param pop name (character string) of variable indicating population
#' @param factors names (character vector) of variables indicating compositional factors
#' @param id_vars character vector of variables indicating sub-populations
#' @param ratefunction user defined character string in R syntax that when evaluated specifies the function defining the rate as a function of factors. if NULL then will assume rate is the product of all factors.
#' @param quietly logical indicating whether interim messages should be outputted indicating progress through the P factors
#' @export
dg2pop <- function(pw, pop, factors, id_vars, ratefunction = NULL, quietly = TRUE) {
  nfact <- length(factors)
  # nest data and extract factors
  df_nested <- lapply(unique(pw[[pop]]), \(x) pw[pw[[pop]] == x, c(factors, id_vars, pop)])

  names(df_nested) <- unique(pw[[pop]])

  # the below function will loop over the indices of your factors, and for
  # each factor A, it will get the BCD... adjusted rates for each population, and
  # spit out the difference too.
  # equivalent to Q1, Q2, ....  in Ben's function
  decomp_out <- lapply(factors, function(x) {
    dg354(df_nested, x,
      pop = pop, factors = factors, id_vars = id_vars,
      ratefunction = ratefunction,
      quietly = quietly
    )
  })


  names(decomp_out) <- factors
  return(decomp_out)
}
