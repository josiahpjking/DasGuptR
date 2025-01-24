#' Decomposes cross-classified population structures into a set of symmetric proportions indicating contribution of individual structural variables.
#' @param df dataframe consisting of one population, including variables indicating cross-classified structure, and a variable indicating size of each cell
#' @param id_vars character vector of variables indicating cross-classified structure.
#' @param nvar variable name (character string) containing cell sizes
#' @export
split_popstr <- function(df,id_vars,nvar){

  np = length(id_vars)
  powers = c(np, sapply(1:(np-1), \(x) (np*choose(np-1,x))))

  .findn <- function(df,tr,ii,sizevar){
    sum(df[ apply(df[, ii, drop=FALSE], 1, \(x) all(x == df[tr, ii, drop=FALSE])), sizevar])
  }

  .onerow <- function(df,tr,id_vars,i,sizevar){

    p1 = .findn(df,tr,id_vars,sizevar)/.findn(df, tr, setdiff(id_vars, i),sizevar)

    p2_pm1 = sapply(2:(np-1), \(y)
                    prod(apply(combn(setdiff(id_vars, i), length(id_vars)-y), 2,
                               \(x) .findn(df, tr, c(i, x), sizevar)/.findn(df, tr, c(x), sizevar))))

    pp = .findn(df,tr,i,sizevar)/sum(df[[sizevar]])

    prod(sapply(1:np, \(x) c(p1,p2_pm1,pp)[x]^(1/powers[x])))
  }



  if(np==1){
    pop_str <- data.frame(df[[nvar]]/sum(df[[nvar]]))
    names(pop_str) <- id_vars
  } else {
    pop_str <-
      lapply(id_vars, \(ix)
             sapply(1:nrow(df), \(rw) .onerow(df,rw,id_vars,ix,nvar)))
    names(pop_str) <- id_vars
    pop_str <- as.data.frame(pop_str)
  }
  return(pop_str)
}




