#' Standardisation and decomposition of rates over P rate-factors and N populations.
#' Outputs a ? object
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered
#' @param pop tidyselect variable indicating population ID
#' @param ... tidyselect variables indicating rate-factors
#' @export
#' @examples
#' ......
#DasGupt_TS<-function(df,f,pop,populations=NULL,baseline=NULL,method="DG",...){
DasGupt_Npop<-function(df,pop,...,baseline=NULL,id_vars=NULL){
  pop=enquo(pop)
  factrs=map_chr(enquos(...),quo_name)
  nfact=length(factrs)
  allpops=pull(df,!!pop) %>% unique

  #all pairwise comparisons of years (will filter these depending on user input of baseline)
  allpops %>% combinat::combn(.,2) %>% as_tibble(.,.name_repair="universal") -> pairwise_pops
  pairwise_pops<-bind_cols(pairwise_pops, pairwise_pops[c(2,1),])

  #####
  #future user inputs
  #####
  #select the set of years you want to include in the time series...

  #for comparing specific pops/years. @param populations=NULL
  #if(!is.null(populations)){
    #allpops=allpops[allpops %in% populations]
  #}

  ##########
  #THE DAS GUPTA METHOD
  ##########

  ##### N population standardisation
  if(length(allpops)>2){
    #let's change the names to ensure we keep track of which pairwise standardisations are which
    #okay, so start by applying dasgupt2pop to each pairwise combination
    map(pairwise_pops,~dplyr::filter(df,year %in% .x) %>% mutate(
      orderedpop=factor(!!pop,c(.x[[1]],.x[[2]])))) %>%
      map(.,~DasGupt_2pop(.,orderedpop,factrs)) -> dg2p_res
    names(dg2p_res)<-map(pairwise_pops,~paste0("pops",paste(.,collapse="vs")))
    #unlist and tibble up
    dg2p_res %>% map(.,~unlist(.,recursive=F) %>% as_tibble) -> dg2p_res
    DG_OUT = list()
    for(f in factrs){
      #separate out the adjusted rates and the factor effects. DG has d
      dg2p_res %>% unlist(recursive = F) %>% as_tibble() %>%
        select(contains(f),-contains("factor")) -> dg2p_rates
      dg2p_res %>% unlist(recursive = F) %>% as_tibble() %>%
        select(contains(paste0(f,".factor"))) -> dg2p_facteffs

      if(!is.null(baseline)){
        standardized_rates <- dg2p_rates %>% select(starts_with(paste0("pops",baseline))) %>% select(-ends_with(paste0("pop",baseline)))
        names(standardized_rates)<-map_chr(strsplit(names(standardized_rates),"\\."),3)
        difference_effects <- dg2p_facteffs %>% select(starts_with(paste0("pops",baseline)))
        names(difference_effects)<-gsub("pops","diff",map_chr(strsplit(names(difference_effects),"\\."),1)) %>% gsub("vs","_",.)
      }else{
        #std_rates
        standardized_rates<-map_dfc(allpops,~Npops_std_rates(dg2p_rates,allpops,as.character(.),f))
        #these are the standardized rate for factor f in each year, stnadardixed over all Ys.
        difference_effects<-map_dfc(pairwise_pops,~Npops_factor_effects(dg2p_facteffs,.,allpops))
      }
      DG_OUT[[f]]=bind_cols(standardized_rates,difference_effects)
    }
  }else{
  # ONLY 2 populations, use dasgupt_2pop directly.
    DasGupt_2pop(df,!!pop,factrs) %>%
      map(., ~rename(.,!!paste0("diff",paste(allpops,collapse="_")):=factoreffect)) -> dg2p_res
    DG_OUT = list()
    for(f in factrs){
      DG_OUT[[f]]=bind_cols(
        select(dg2p_res[[f]],starts_with("pop")),
        select(dg2p_res[[f]],starts_with("diff"))
      )
    }
  }


  if(!missing(id_vars)){
     id_vars=enquo(id_vars)
     map(DG_OUT, ~bind_cols(df %>% select(!!id_vars) %>% distinct,.)) %>%
       map2_dfr(.,names(.),~mutate(.x,factor=.y))
  }else{return(DG_OUT)}
}
