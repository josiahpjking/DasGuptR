#' Inner function called by dg2pop
#' @param df2 dataframe in which rows are populations, column 'factor_df' is a nested dataframe of rate-factors, and column 'pop_prods' is the rowProducts of 'factor_df'.
#' @param i the index of the factrs vector which is being adjusted for (the alpha in P-alpha)
#' @param factrs character vector of rate-factors
#' @param ratefunction allows user to define rate as a specific function F of factors. This should be a character string of the r syntax, with the factor names. Defaults to the product (e.g., "a*b").
#' @export
#' @examples
#' ......
#'
dg354<-function(df2,i,factrs,ratefunction,quietly=TRUE){
  #how many factors?
  nfact=length(factrs)
  #this is the one we're interested in right now
  facti=factrs[i]
  pops = levels(df2 %>% droplevels %>% pull(pop))
  # message
  if(!quietly){print(paste0("comparing populations ",distinct(df2,pop) %>% pull(pop) %>% paste(collapse=" and ")," . Factor = ",facti))}

  #these are all the population factors (for both populations), spread.
  pop_facts =
    df2 %>% dplyr::select(pop,factor_df) %>%
    tidyr::pivot_wider(names_from=pop,values_from=factor_df) %>%
    tidyr::unnest(tidyselect::everything(),names_sep="_")
  allfacts = names(pop_facts)
  allfactsA = allfacts[1:nfact]
  allfactsB = allfacts[(nfact+1):length(allfacts)]

  #these are the all the combinations of P-1 factors from 2 populations
  allperms = t(combn(allfacts[!grepl(facti,allfacts)],length(allfacts)/2-1))

  #because we need to distinguish between sets by how many are from pop1 and how many from pop2:
  countBs = apply(allperms, 1, function(x) length(which(x %in% allfactsB)))
  countBs = ifelse(countBs %in% c(0,(length(allfacts)/2-1)),0,countBs)

  # we also need to remove any sets in which factors come up twice (e.g. age_str and age_str1)
  countfacts = sapply(factrs, function(y) apply(allperms, 1, function(x) sum(grepl(y,x))))
  countdup = rowSums(countfacts == 2)

  #these are denominators for the 3.54 eq
  eqp = sapply(countBs, function(x) nfact*max(dim(combn(nfact-1,x))))
  eqp = eqp[countdup==0]

  relperms = allperms[countdup==0,]
  if(is.null(dim(relperms))){relperms = as.array(relperms)}
  # factor data
  fdata = apply(relperms, 1, function(x) pop_facts[x])
  fdata_clean = lapply(fdata, function(x)
    dplyr::rename_with(x,.fn = ~gsub(paste0(pops,"_", collapse="|"), "",.),
                       .cols = tidyselect::everything()))

  # rates / Aa
  rfunct = sapply(fdata_clean, function(x) dplyr::mutate(x, rf = eval(parse(text=gsub(facti,"1",ratefunction))))
         %>% pull(rf))

  if(is.null(dim(rfunct))){
    eq354 = aggregate(rfunct, by = list(eqp), FUN = sum)
    QAa = sum(eq354[,2]/eq354[,1])
  }else{
    eq354 = apply(rfunct, 1, function(x) aggregate(x, by = list(eqp), FUN = sum))
    QAa = sapply(eq354, function(x) sum(x[,2]/x[,1]))
  }



  popAi = pop_facts[[paste0(pops[1],"_",facti)]]*QAa
  popBi = pop_facts[[paste0(pops[2],"_",facti)]]*QAa
  diff=popBi-popAi

  res = data.frame(
    popAi=popAi,
    popBi=popBi,
    factoreffect=diff
  )
  names(res) = c(paste0("pop_",pops,".adj",rev(pops)), paste0("diff_",paste0(pops,collapse="")))
  return(res)
}
