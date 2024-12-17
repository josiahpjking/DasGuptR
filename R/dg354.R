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
  facti=i
  pops = unique(names(df2))

  # message
  if(!quietly){print(paste0("comparing populations ",paste(unique(names(df2)), collapse=" and ")," . Factor = ",facti))}

  #these are all the population factors (for both populations), spread.
  # pop_facts =
  #   df2 %>% dplyr::select(pop,factor_df) %>%
  #   tidyr::pivot_wider(names_from=pop,values_from=factor_df) %>%
  #   tidyr::unnest(tidyselect::everything(),names_sep="_")
  pop_facts = do.call(rbind,df2)



  allfacts = paste0(rep(pops,e=nfact),
                    rep(names(pop_facts),2))

  allfactsA = allfacts[1:nfact]
  allfactsB = allfacts[(nfact+1):length(allfacts)]
  #these are the all the combinations of P-1 factors from 2 populations
  allperms = t(combn(allfacts[!allfacts %in% paste0(pops,facti)],length(allfacts)/2-1))

  #because we need to distinguish between sets by how many are from pop1 and how many from pop2:
  countBs = apply(allperms, 1, function(x) length(which(x %in% allfactsB)))
  countBs = ifelse(countBs %in% c(0,(length(allfacts)/2-1)),0,countBs)

  # we also need to remove any sets in which factors come up twice (e.g. age_str and age_str1)
  countfacts = sapply(factrs, \(y) apply(gsub(paste0(pops,collapse="|"),"",allperms), 1, \(x) sum(x==y)))

  countdup = rowSums(countfacts == 2)


  #these are denominators for the 3.54 eq
  eqp = sapply(countBs, function(x) nfact*max(dim(combn(nfact-1,x))))
  eqp = eqp[countdup==0]

  #here is all the factor data:
  relperms = allperms[countdup==0,]
  if(is.null(dim(relperms))){relperms = as.array(relperms)}

  fdata =
    apply(t(relperms),2,
        function(x)
          sapply(x,
                 function(y)
                   pop_facts[
                     gsub(paste0(factrs,collapse="|"),"",y),
                     gsub(paste0(pops,collapse="|"),"",y)
                   ]
                 )
    )


  if(is.vector(fdata)){ fdata = matrix(fdata, nrow=1) }

  fdata_clean = vector(mode="list",length=dim(fdata)[2])

  for(l in 1:length(fdata_clean)){
    fdata_clean[[l]] = fdata[,l]
    names(fdata_clean[[l]]) = gsub(paste0(pops,collapse="|"),"",t(relperms))[,l]
  }


  # rates / Aa
  tmp_ratefunction = gsub(paste0("\\b",facti,"\\b"),"1",ratefunction)

  rfunct = sapply(fdata_clean, function(x) eval(parse(text = tmp_ratefunction), envir = as.list(x)))


  if(is.null(dim(rfunct))){
    eq354 = aggregate(rfunct, by = list(eqp), FUN = sum)
    QAa = sum(eq354[,2]/eq354[,1])
  }else{
    eq354 = apply(rfunct, 1, function(x) aggregate(x, by = list(eqp), FUN = sum))
    QAa = sapply(eq354, function(x) sum(x[,2]/x[,1]))
  }

  popAi = pop_facts[pops[1],facti]*QAa
  popBi = pop_facts[pops[2],facti]*QAa
  diff=popBi-popAi

  res = data.frame(
    adj.rate=c(popAi,popBi),
    pop=pops,
    adj.set=rev(pops),
    diff=c(diff,-diff),
    diff.calc=c(paste0(pops,collapse="-"),
           paste0(rev(pops),collapse="-")
    ),
    factor=facti
  )

  return(res)
}
