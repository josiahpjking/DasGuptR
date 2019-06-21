#' Standardisation and decomposition of rates over P rate-factors and N populations.
#' Outputs a ? object
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered
#' @param pop tidyselect variable indicating population ID
#' @param ... tidyselect variables indicating rate-factors
#' @export
#' @examples
#' ......
#DasGupt_TS<-function(df,f,pop,populations=NULL,baseline=NULL,method="DG",...){
DasGupt_Npop<-function(df,pop,...){
  pop=enquo(pop)
  factrs=map_chr(enquos(...),quo_name)
  nfact=length(factrs)
  #factrs=c("prev","age_str","freq","disposal_prop","crime_type_prop")

  #factor of interest.
  #f
  allpops=distinct(df,!!pop) %>% unlist %>% unname

  populations=NULL
  if(!is.null(populations)){
    allpops=allpops[allpops %in% populations]
  }

  baseline=NULL
  # if(is.null(baseline)){
    allpops %>% combinat::combn(.,2) %>% as_tibble(.,.name_repair="universal") -> pairwise_pops
  # } else{
  #   allpops[allpops!=baseline] %>% combinat::combn(.,1) -> compyears
  #   matrix(c(rep(baseline,length(compyears)),compyears),ncol=length(compyears),byrow=T) %>%
  #     as_tibble() -> pairwise_pops
  # }

    #####
    # N POP STANDARDISATION
    #####
    if(length(allpops)>2){
      #let's change the names to ensure we keep track of which pairwise standardisations are which
      #okay, so start by applying dasgupt2pop to each pairwise combination
      map(pairwise_pops,~filter(df,!!pop %in% .x)) %>%
        map(.,~DasGupt_2pop(.,!!pop,factrs)) -> dg2p_res
      names(dg2p_res)<-map(pairwise_pops,~paste0("pops",paste(.,collapse="vs")))
      #unlist and tibble up
      dg2p_res %>% map(.,~unlist(.,recursive=F) %>% as_tibble) -> dg2p_res

      DG_OUT<-list(factrs)
      for(f in factrs){
        #separate out the adjusted rates and the factor effects. DG has d
        dg2p_res %>% unlist(recursive = F) %>% as_tibble() %>%
          select(contains(f),-contains("factor")) -> dg2p_rates
        #std_rates
        standardized_rates<-map_dfc(allpops,~Npops_std_rates(dg2p_rates,allpops,as.character(.),f))
        #these are the standardized rate for factor f in each year, stnadardixed over all Ys.

        dg2p_res %>% unlist(recursive = F) %>% as_tibble() %>%
          select(contains(paste0(f,".factor"))) -> dg2p_facteffs
        difference_effects<-map_dfc(pairwise_pops,~Npops_factor_effects(dg2p_facteffs,.,allpops))

        DG_OUT[[f]]=list("standardised_rates" = standardized_rates, "factor_effects" = difference_effects)
      }
      return(DG_OUT)
    }else{
      DasGupt_2pop(df,!!pop,factrs) %>%
        map(., ~rename(.,!!paste0("diff",paste(allpops,collapse="_")):=factoreffect)) -> dg2p_res
      DG_OUT = list(c("prev","age_str","freq","disposal_prop","crime_type_prop"))
      for(f in c("prev","age_str","freq","disposal_prop","crime_type_prop")){
        DG_OUT[[f]]=list(
          "standardised_rates" = select(dg2p_res[[f]],starts_with("pop")),
          "factor_effects" = select(dg2p_res[[f]],starts_with("diff")))
      }
      return(DG_OUT)
    }
}
