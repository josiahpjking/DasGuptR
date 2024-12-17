#' Standardisation and decomposition of rates over P rate-factors and 2 populations.
#' For simplicity, suggest using dgnpop, which will default to dg2pop in the case of 2 populations.
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered. must have column named "pop" indicating the population ID.
#' @param factrs character vector of rate-factors
#' @param ratefunction allows user to define rate as a specific function F of factors. This should be a character string of the r syntax, with the factor names. Defaults to the product (e.g., "a*b").
#' @export
dg2pop<-function(pw,pop,factors,ratefunction=NULL,quietly=TRUE){

  nfact=length(factors)
  #nest data and extract factors
  df_nested <- lapply(unique(pw[[pop]]), \(x) pw[pw[[pop]]==x, factors])
  names(df_nested) = unique(pw[[pop]])

  #the below function will loop over the indices of your factors, and for
  #each factor A, it will get the BCD... adjusted rates for each population, and
  #spit out the difference too.
  #equivalent to Q1, Q2, ....  in Ben's function
  if(!is.null(ratefunction)){

    decomp_out = lapply(factors, function(x) dg354(df_nested,x,factors,ratefunction,quietly=quietly))

  }else{

    prodrf=paste(factors,collapse="*")
    decomp_out = lapply(factors, function(x) dg354(df_nested,x,factors,prodrf,quietly=quietly))

  }
  names(decomp_out) = factors
  return(decomp_out)
}
