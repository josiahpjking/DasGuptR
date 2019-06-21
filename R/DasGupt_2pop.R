#' Standardisation and decomposition of rates over P rate-factors and 2 populations. 
#' Outputs a ? object 
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered
#' @param pop tidyselect variable indicating population ID
#' @param factrs character vector of rate-factors
#' @export
#' @examples
#' ......
DasGupt_2pop<-function(df,pop,factrs){
  
  pop=enquo(pop)
  nfact=length(factrs)
  print(factrs)

  #nest and make factor matrix
  df %>% group_by(!!pop) %>%
    nest() %>%
    mutate(
      factor_df = map(data, magrittr::extract,factrs), #replace factrs with sym(...)
      factor_mat = map(factor_df,as.matrix),
      pop_prods=map(factor_mat,rowProds) #calculate total products (can simply divide by \alpha afterwards)
    ) -> df_nested

  #the get_effect function will loop over the indices of your factors, and for 
  #each factor A, it will get the BCD... adjusted rates for each population, and
  #spit out the difference too.
  #equivalent to Q1, Q2, ....  in Ben's function
  decomp_out<-suppressMessages(map(1:nfact,~DGadjust_ratefactor(df_nested,pop,.,factrs)))
  names(decomp_out)<-factrs
  return(decomp_out)
}
