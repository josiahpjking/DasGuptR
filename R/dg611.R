#' Das Gupta equation 6.11: Standardises rates across populations
#' @param srates a dataframe/tibble object of standardised rates from dg2pop
#' @param all_p character or numeric vector of all N populations
#' @param y character/numeric indicating a single population
#' @param factor string indicating rate-factor being standardised.
#' @return data.frame object including K-a standardised rates for each population for given factor a, across N populations
#' @export
dg611 <- function(srates, all_p, y, factor) {
  n <- length(all_p)

  # EQ 6.11
  eq6.11.a <- mean(srates[srates$pop == y, "rate"])

  srates[srates$pop != y | srates$std.set != y, "rate"]

  eq6.11.b <-
    sum(
      sapply(all_p[all_p != y], \(x)
      sum(srates[srates$pop == x & srates$std.set != y, "rate"]) -
        ((n - 2) * srates[srates$pop == x & srates$std.set == y, "rate"]))
    ) / (n * (n - 1))


  res <- data.frame(
    rate = eq6.11.a + eq6.11.b,
    pop = y,
    std.set = paste0(all_p[all_p != y], collapse = "."),
    factor = factor
  )
  return(res)
}
