#' Decomposes cross-classified population structures into a set of symmetric proportions indicating contribution of individual structural variables.
#' @param x dataframe consisting of one population, including variables indicating cross-classified structure, and a variable indicating size of each cell
#' @param pop variable name (character string) containing population identifier
#' @param id_vars character vector of variables indicating cross-classified structure.
#' @param crossclassified variable name (character string) containing cell sizes or proportions
#' @export
dgcc <- function(x, pop, id_vars, crossclassified) {
  tmpdf <- as.data.frame(x)

  for (p in unique(tmpdf[[pop]])) {
    str_vars <- split_popstr(tmpdf[tmpdf[[pop]] == p, ], id_vars = id_vars, nvar = crossclassified)
    tmpdf[tmpdf[[pop]] == p, names(str_vars)] <- str_vars
  }

  return(tmpdf)
}
