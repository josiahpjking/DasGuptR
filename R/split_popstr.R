#' Decomposes cross-classified population structures into a set of symmetric proportions indicating contribution of individual structural variables.
#' @param x dataframe consisting of one population, including variables indicating cross-classified structure, and a variable indicating size of each cell
#' @param id_vars character vector of variables indicating cross-classified structure.
#' @param nvar variable name (character string) containing cell sizes
#' @export
split_popstr <- function(x, id_vars, nvar) {
  tmpdf <- as.data.frame(x)

  np <- length(id_vars)
  powers <- c(np, sapply(1:(np - 1), \(x) (np * choose(np - 1, x))))

  .findn <- function(ddf, tr, ii, sizevar) {
    sum(ddf[apply(ddf[, ii, drop = FALSE], 1, \(x) all(x == ddf[tr, ii, drop = FALSE])), sizevar])
  }

  .onerow <- function(ddf, tr, id_vars, i, sizevar) {
    p1 <- .findn(ddf, tr, id_vars, sizevar) / .findn(ddf, tr, setdiff(id_vars, i), sizevar)

    p2_pm1 <- sapply(2:(np - 1), \(y)
    prod(apply(
      combn(setdiff(id_vars, i), length(id_vars) - y), 2,
      \(x) .findn(ddf, tr, c(i, x), sizevar) / .findn(ddf, tr, c(x), sizevar)
    )))

    pp <- .findn(ddf, tr, i, sizevar) / sum(ddf[[sizevar]])

    prod(sapply(1:np, \(x) c(p1, p2_pm1, pp)[x]^(1 / powers[x])))
  }



  if (np == 1) {
    pop_str <- data.frame(tmpdf[[nvar]] / sum(tmpdf[[nvar]]))
    names(pop_str) <- paste0(id_vars, "_struct")
  } else {
    pop_str <-
      lapply(id_vars, \(ix)
      sapply(seq_len(nrow(tmpdf)), \(rw) .onerow(tmpdf, rw, id_vars, ix, nvar)))
    names(pop_str) <- paste0(id_vars, "_struct")
    pop_str <- as.data.frame(pop_str)
  }
  return(pop_str)
}
