#' Inner function called by DasGupt_2pop and DasGupt_Npop
#' Outputs a ? object
#' @param df dataframe in which rows are populations, column 'factor_df' is a nested dataframe of rate-factors, and column 'pop_prods' is the rowProducts of 'factor_df'.
#' @param pop tidyselect variable indicating population ID
#' @param factrs character vector of rate-factors
#' @export
#' @examples
#' ......
DGadjust_ratefactor<-function(df2,pop,i,factrs,ratefunction){
  #quick fix
  if(exists("unnest_legacy",where="package:tidyr",mode="function")){unnest<-unnest_legacy}

  #how many factors?
  nfact=length(factrs)
  #this is the one we're interested in right now
  facti=factrs[i]

  #print(paste0("comparing: ",distinct(df2,!!pop) %>% pull(!!pop) %>% paste(collapse=":")," Factor = ",facti))


  #these are all the population factors (for both populations), spread.
  #this means that indices 1:n/2 are pop1, and n/2:n are pop2. They are distinguished by a "1" in the name.
  #JK: IMPORTANT - FACTOR NAMES MUST NOT HAVE A "1" IN THEM ALREADY!
  pop_facts<-df2 %>% dplyr::select({{pop}},factor_df) %>% spread({{pop}},factor_df) %>% unnest
  allfacts=names(pop_facts)
  allfacts0 = allfacts[1:nfact]
  allfacts1 = allfacts[(nfact+1):length(allfacts)]

  #these are the all the combinations of P-1 factors from 2 populations
  allperms<-combn(allfacts[!(allfacts %in% c(facti,paste0(facti,1)))],length(allfacts)/2-1) %>% t %>% as.data.frame(.,stringsAsFactors=FALSE)

  #because we need to distinguish between sets by how many are from pop1 and how many from pop2, we'll count the 1s and absence of 1s
  # we also need to remove any sets in which factors come up twice (e.g. age_str and age_str1)
  count1s <- apply(allperms, 1, function(x) length(which(x %in% allfacts1)))
  count0s <- apply(allperms, 1, function(x) length(which(x %in% allfacts0)))
  countmult <- apply(data.frame(lapply(allperms, function(x) {gsub("1","",x)})), 1, function(x) sum(duplicated(x)|duplicated(x, fromLast = TRUE)))
  allperms %>% mutate(
    #c0s=ifelse(count0s %in% c(0,(length(allfacts)/2-1)),0,count0s),
    #c1s=ifelse(count1s %in% c(0,(length(allfacts)/2-1)),0,count1s),
    eqp=map_dfc(0:floor(nfact/2),~ifelse(count0s==.|count1s==.,.,0)) %>% rowSums,
    cMs=countmult
  ) %>% filter(cMs==0) -> allperms

  #make an id for each
  allperms$f_id<-paste0("f",1:nrow(allperms))

  #these are the parts of the DG 3.54 equation (page 32)
  eq_parts <- allperms %>% group_by(eqp) %>%
    summarise(
      n=n(),
      F_eqs=list(f_id)
    ) %>% ungroup
  #these are the denominators for each part
  denominators = map_dbl(1:nrow(eq_parts)-1,~nfact*(ncol(combn(nfact-1,.))))

  #extract all the data for each F() calculation
  #one is for when alpha is from pop1, and one when alpha is from pop2
  allperms <- allperms %>% as_tibble %>%
    mutate(
      data=map(1:nrow(allperms),~pop_facts[allfacts[allfacts %in% c(facti,allperms[.,1:((length(allfacts)/2)-1)])]]),
      data1=map(1:nrow(allperms),~pop_facts[allfacts[allfacts %in% c(paste0(facti,1),allperms[.,1:((length(allfacts)/2)-1)])]])
    )

  #this is to clean up the 1s. Again, this aspect could be a lot better...
  colClean <- function(x){ colnames(x) <- gsub("1", "", colnames(x)); x }

  #Now we map the rate function (user defined) onto the data.
  allperms %>% mutate(
    data_rn = map(data,colClean),
    rfunct = map(data_rn,~mutate(.,rf=eval(parse(text=ratefunction))) %>% pull(rf)),

    data1_rn = map(data1,colClean),
    rfunct1 = map(data1_rn,~mutate(.,rf=eval(parse(text=ratefunction))) %>% pull(rf))
  ) %>% select(-c(data,data_rn,cMs,data1,data1_rn)) -> allperms


  #spread, unnest
  feq_data = allperms %>% select(f_id, rfunct) %>% spread(f_id,rfunct) %>% unnest
  feq_data1 = allperms %>% select(f_id, rfunct1) %>% spread(f_id,rfunct1) %>% unnest

  eq_parts %>%
    mutate(
      top_part = map(F_eqs, ~select(feq_data,.) %>% rowSums),
      top_part1 = map(F_eqs, ~select(feq_data1,.) %>% rowSums),
      bottom_part = denominators,
      eq = map2(top_part,bottom_part,~(.x/.y)),
      eq1 = map2(top_part1,bottom_part,~(.x/.y))
    ) -> eq_parts
  pop1=eq_parts %>% select(eq1) %>% unlist(recursive = F) %>% as_tibble() %>% rowSums
  pop2=eq_parts %>% select(eq) %>% unlist(recursive = F) %>% as_tibble() %>% rowSums
  diff=pop1-pop2

  tibble(
    !!paste0("pop",df2 %>% pull({{pop}}) %>% .[1] %>% as.character):=pop1,
    !!paste0("pop",df2 %>% pull({{pop}}) %>% .[2] %>% as.character):=pop2,
    factoreffect=diff
  )

}
