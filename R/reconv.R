#' Arabidopsis QTL data on gravitropism
#'
#' Data from a QTL experiment on gravitropism in
#' Arabidopsis, with data on 162 recombinant inbred lines (Ler x
#' Cvi). The outcome is the root tip angle (in degrees) at two-minute
#' increments over eight hours.
#'
#' @docType data
#'
#' @usage data(reconv)
#'
#' @format An object of class \code{"cross"}; see \code{\link[qtl]{read.cross}}.
#'
#' @keywords datasets
#'
#' @references Scottish Government Reconviction data:
#' (\href{https://www.gov.scot/publications/reconviction-rates-scotland-2016-17-offender-cohort/}{2016/17})
#'
#' @source \href{https://phenome.jax.org/projects/Moore1b}{QTL Archive}
#'
#' @examples
#' data(reconv)
#' dg_data <- DasGupt_Npop(reconv,pop=year,prev,age_str,id_vars=c(Age,Gender))
#'
"reconv"
