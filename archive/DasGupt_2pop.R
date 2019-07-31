#' Standardisation and decomposition of rates over P rate-factors and 2 populations.
#' Outputs a ? object
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered
#' @param pop tidyselect variable indicating population ID
#' @param factrs character vector of rate-factors
#' @export
#' @examples
#' ......
DasGupt_2pop<-function(df,pop,factrs,ratefunction=NULL){
  pop=enquo(pop)
  nfact=length(factrs)

  #nest and make factor matrix
  df %>% group_by(!!pop) %>%
    nest() %>%
    mutate(
      factor_df = map(data, magrittr::extract,factrs)
    ) -> df_nested

  #the below function will loop over the indices of your factors, and for
  #each factor A, it will get the BCD... adjusted rates for each population, and
  #spit out the difference too.
  #equivalent to Q1, Q2, ....  in Ben's function
  if(!is.null(ratefunction)){
    decomp_out<-map(1:nfact,~DGadjust_ratefactor(df_nested,!!pop,.,factrs,ratefunction))
  }else{
    prodrf=paste(factrs,collapse="*")
    decomp_out<-map(1:nfact,~DGadjust_ratefactor(df_nested,!!pop,.,factrs,prodrf))
    #decomp_out<-map(1:nfact,~DGadjust_ratefactor_old(df_nested,!!pop,.,factrs))
  }
  names(decomp_out)<-factrs

  # decomp_out <-
  # decomp_out %>%
  #   tibble(
  #     factor = names(.),
  #     results = .
  #   ) %>%
  #   unnest()

  return(decomp_out)
}
