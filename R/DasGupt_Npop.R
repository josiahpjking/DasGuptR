#' Standardisation and decomposition of rates over P rate-factors and N populations.
#' Outputs a ? object
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered
#' @param pop tidyselect variable indicating population ID
#' @param ... tidyselect variables indicating rate-factors
#' @param id_vars character vector of variable names in dataframe to attach back to output (useful if analysing sub-population specific rates)
#' @param baseline baseline population to standardise against. if NULL then will do Das Gupta's full N-population standardisation.
#' @param ratefunction allows user to define rate as a specific function F of factors. This should be a character string of the r syntax, with the factor names. Defaults to the product (e.g., "a*b").
#' @export
#' @examples
#' DasGupt_Npop(df,year,prev,freq,baseline=NULL,id_vars=c("age","sex"),ratefunction="prev*freq")

DasGupt_Npop<-function(df,pop,...,baseline=NULL,id_vars=NULL,ratefunction=NULL){
  factrs=map_chr(enquos(...),quo_name)
  nfact=length(factrs)
  allpops=pull(df,{{pop}}) %>% unique

  #all pairwise comparisons of years (will filter these depending on user input of baseline)
  allpops %>% combinat::combn(.,2) %>% as.data.frame -> pairwise_pops
  pairwise_pops<-bind_cols(pairwise_pops, pairwise_pops[c(2,1),])


  ##########
  #THE DAS GUPTA METHOD
  ##########

  ##### N population standardisation
  if(length(allpops)>2){
    #let's change the names to ensure we keep track of which pairwise standardisations are which
    #okay, so start by applying dasgupt2pop to each pairwise combination
    print("Standardising and decomposing for all pairwise comparisons...")
    map(pairwise_pops,~dplyr::filter(df,year %in% .x) %>% mutate(
      orderedpop=factor({{pop}},c(.x[[1]],.x[[2]])))) %>%
      map(.,~DG_2pop(.,orderedpop,factrs,ratefunction)) -> dg2p_res

    names(dg2p_res)<-map(pairwise_pops,~paste0("pops",paste(.,collapse="vs")))
    #unlist and tibble up
    dg2p_res %>% map(.,~unlist(.,recursive=F) %>% as_tibble(.name_repair = "universal")) -> dg2p_res
    DG_OUT = list()
    for(f in factrs){
      #separate out the adjusted rates and the factor effects. DG has d
      dg2p_res %>% unlist(recursive = F) %>% as_tibble(.name_repair = "universal") %>%
        select(contains(f),-contains("factor")) -> dg2p_rates
      dg2p_res %>% unlist(recursive = F) %>% as_tibble(.name_repair = "universal") %>%
        select(contains(paste0(f,".factor"))) -> dg2p_facteffs

      if(!is.null(baseline)){
        standardized_rates <- dg2p_rates %>% select(starts_with(paste0("pops",baseline))) %>% select(-ends_with(paste0("pop",baseline)))
        names(standardized_rates)<-map_chr(strsplit(names(standardized_rates),"\\."),3)
        difference_effects <- dg2p_facteffs %>% select(starts_with(paste0("pops",baseline)))
        names(difference_effects)<-gsub("pops","diff",map_chr(strsplit(names(difference_effects),"\\."),1)) %>% gsub("vs","_",.)
      }else{
        #std_rates
        print(paste0("Standardizing P-",f," across N pops..."))
        standardized_rates<-map_dfc(allpops,~DG_Npops_std(dg2p_rates,allpops,as.character(.),f))
        #these are the standardized rate for factor f in each year, stnadardixed over all Ys.
        print(paste0("Getting decomposition effects for P-",f," standardised rates..."))
        difference_effects<-map_dfc(pairwise_pops,~DG_Npops_decomp(dg2p_facteffs,.,allpops))
      }
      DG_OUT[[f]]=bind_cols(standardized_rates,difference_effects)
    }
  }else{
  # ONLY 2 populations, use dasgupt_2pop directly.
    DG_2pop(df,{{pop}},factrs,ratefunction) %>%
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
     #id_vars=enquo(id_vars)
     map(DG_OUT, ~bind_cols(df %>% select({{id_vars}}) %>% distinct,.)) %>%
       map2_dfr(.,names(.),~mutate(.x,factor=.y))
  }else{return(DG_OUT)}
}
