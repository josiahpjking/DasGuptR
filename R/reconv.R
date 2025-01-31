#' Scottish Reconvictions data 2004-2016
#'
#'
#' @docType data
#'
#' @usage data(reconv)
#'
#' @keywords datasets
#'
#' @references Scottish Government Reconviction data:
#' (\href{https://www.gov.scot/publications/reconviction-rates-scotland-2016-17-offender-cohort/}{2016/17})
#'
#'
#' @examples
#' data(reconv)
#' dgnpop(reconv, pop="year", factors=c("prev_rate"), id_vars=c("Sex","Age"), crossclassified="offenders") |> dg_plot()
#'
"reconv"
