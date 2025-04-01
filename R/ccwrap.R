#' Wrapper for cross-classified data that standardises rates across a pair of populations. Because these are (r+r')/2 * Q(a_i), this requires 1) doing the rate standardisation on each sub-population, 2) performing the standardisation on the cross classified structure variables, 3) multiplying and (optionally) aggregating up
#' @param pw dataframe containing two populations worth of factor data, with columns specifying 1) population and 2) each rate-factor to be considered. must have column named "pop" indicating the population ID.
#' @param pop name (character string) of variable indicating population
#' @param factors names (character vector) of variables indicating compositional factors
#' @param id_vars character vector of variables indicating sub-populations
#' @param crossclassified character string of variable indicating size of sub-population. If specified, the proportion of each population in a given sub-population (e.g. each age-sex combination) is re-expressed as a product of symmetrical expressions representing the different variables (age, sex) constituting the sub-populations.
#' @param agg logical indicating whether, when cross-classified data is used, to output should be aggregated up to the population level
#' @param ratefunction user defined character string in R syntax that when evaluated specifies the function defining the rate as a function of factors. if NULL then will assume rate is the product of all factors.
#' @param quietly logical indicating whether interim messages should be outputted indicating progress through the P factors
#' @return data.frame that includes K-a standardised rates for each population and each factor a, along with differences between standardised rates
#' @export
ccwrap <- function(pw, pop, factors, id_vars, crossclassified, agg, ratefunction = NULL, quietly = TRUE) {
  dgo_rate <- dg2pop(pw,
    pop = pop, factors = factors, id_vars = id_vars,
    ratefunction = ratefunction, quietly = quietly
  )
  dgo_rate <- do.call(rbind, dgo_rate)

  dgo_size <- dg2pop(pw,
    pop = pop, factors = crossclassified, id_vars = id_vars,
    ratefunction = paste0(crossclassified, "/sum(", crossclassified, ")"),
    quietly = quietly
  )
  dgo_size <- do.call(rbind, dgo_size)

  dgo_struct <- dg2pop(
    dgcc(pw,
      pop = pop,
      id_vars = id_vars, crossclassified = crossclassified
    ),
    pop = pop,
    factors = paste0(id_vars, "_struct"),
    id_vars = id_vars,
    ratefunction = paste0(paste0(id_vars, "_struct"), collapse = "*"),
    quietly = quietly
  )
  dgo_struct <- do.call(rbind, dgo_struct)

  # [bc..]A * tT2
  dgo_struct$rate <- dgo_struct$rate * with(dgo_rate, (rate + (rate - diff)) / 2)
  # T * nN2
  dgo_rate$rate <- dgo_rate$rate * with(dgo_size, (rate + (rate - diff)) / 2)

  DG_OUT <- rbind(
    dgo_rate,
    dgo_struct
  )

  if (agg) {
    DG_OUT <-
      data.frame(
        rate = unlist(by(DG_OUT$rate, list(DG_OUT$pop, DG_OUT$factor), sum, simplify = FALSE)),
        pop = unlist(by(DG_OUT$pop, list(DG_OUT$pop, DG_OUT$factor), unique, simplify = FALSE)),
        std.set = unlist(by(DG_OUT$std.set, list(DG_OUT$pop, DG_OUT$factor), unique, simplify = FALSE)),
        factor = unlist(by(DG_OUT$factor, list(DG_OUT$pop, DG_OUT$factor), unique, simplify = FALSE))
      )
    DG_OUT$diff <- unlist(by(DG_OUT$rate, list(DG_OUT$factor), \(x)
    c(diff(x), -diff(x)), simplify = FALSE))
  } else {
    DG_OUT <- DG_OUT[, c("rate", "pop", "std.set", "diff", "diff.calc", "factor", id_vars)]
  }
  row.names(DG_OUT) <- NULL
  return(DG_OUT)
}
