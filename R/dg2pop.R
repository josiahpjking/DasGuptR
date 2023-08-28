#' Standardisation and decomposition of rates over P rate-factors and 2 populations.
#' For simplicity, suggest using dgnpop, which will default to dg2pop in the case of 2 populations.
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered. must have column named "pop" indicating the population ID.
#' @param factrs character vector of rate-factors
#' @param ratefunction allows user to define rate as a specific function F of factors. This should be a character string of the r syntax, with the factor names. Defaults to the product (e.g., "a*b").
#' @export
dg2pop<-function(pw,factrs,ratefunction=NULL,quietly=TRUE){

  nfact=length(factrs)
  #nest data and extract factors
  df_nested <-
    pw %>%
    tidyr::nest(data=-pop) %>%
    dplyr::mutate(factor_df = purrr::map(data, magrittr::extract,factrs))

  #the below function will loop over the indices of your factors, and for
  #each factor A, it will get the BCD... adjusted rates for each population, and
  #spit out the difference too.
  #equivalent to Q1, Q2, ....  in Ben's function
  if(!is.null(ratefunction)){
    decomp_out = lapply(seq_along(1:nfact), function(x) dg354(df_nested,x,factrs,ratefunction,quietly=quietly))
  }else{
    prodrf=paste(factrs,collapse="*")
    decomp_out = lapply(seq_along(1:nfact), function(x) dg354(df_nested,x,factrs,prodrf,quietly=quietly))
  }

  names(decomp_out) = factrs
  return(decomp_out)
}
