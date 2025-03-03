#' US population data 1940-1990
#'
#' @docType data
#'
#' @usage data(uspop)
#'
#' @keywords datasets
#'
#' @examples
#' data(uspop)
#' dgnpop(uspop, pop = "year", factors = c("birthrate"), id_vars = "agebin", crossclassified = "thous")$rates |>
#' dg_plot()
#'
"uspop"
