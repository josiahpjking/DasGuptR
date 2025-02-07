#' internal function called by dg2pop
#' @param df2 list of 2 population dataframes, in which each one contains data for all factors for the relevant population, along with variables indicating population and subpopulations
#' @param i the index of the factors vector which is not being adjusted for (the alpha in "P-alpha standardised rates")
#' @param pop name (character string) of variable indicating population
#' @param factors names (character vector) of variables indicating compositional factors
#' @param id_vars character vector of variables indicating sub-populations
#' @param ratefunction user defined character string in R syntax that when evaluated specifies the function defining the rate as a function of factors. if NULL then will assume rate is the product of all factors.
#' @param quietly logical indicating whether interim messages should be outputted indicating progress
#' @export
#' @examples
#' ......
#'
dg354<-function(df2,i,pop,factors,id_vars,ratefunction,quietly=TRUE){
  #how many factors?
  nfact=length(factors)
  #this is the one we're interested in right now
  facti=factors[i]
  facti=i
  pops = unique(names(df2))
  # message
  if(!quietly){print(paste0("comparing populations ",paste(unique(names(df2)), collapse=" and ")," . Factor = ",facti))}

  #these are all the population factors (for both populations), spread.
  pop_facts = do.call(rbind,df2)

  allfacts = paste0(rep(pops,e=nfact),
                    rep(factors,2))

  allfactsA = allfacts[1:nfact]
  allfactsB = allfacts[(nfact+1):length(allfacts)]
  #these are the all the combinations of P-1 factors from 2 populations
  allperms = t(combn(allfacts[!allfacts %in% paste0(pops,facti)],length(allfacts)/2-1))

  #because we need to distinguish between sets by how many are from pop1 and how many from pop2:
  countBs = apply(allperms, 1, function(x) length(which(x %in% allfactsB)))
  countBs = ifelse(countBs %in% c(0,(length(allfacts)/2-1)),0,countBs)

  # we also need to remove any sets in which factors come up twice (e.g. age_str and age_str1)
  countfacts = sapply(factors, \(y) apply(gsub(paste0(pops,collapse="|"),"",allperms), 1, \(x) sum(x==y)))

  if(nfact == 1){
    allperms = allfacts
    countdup = 0
    relperms = allperms
  }else{
    countdup = rowSums(countfacts == 2)
    #here is all the factor data:
    relperms = allperms[countdup==0,]
  }

  #these are denominators for the 3.54 eq
  eqp = sapply(countBs, function(x) nfact*max(dim(combn(nfact-1,x))))
  eqp = eqp[countdup==0]

  fdata =
    apply(t(relperms),2,
          function(x)
            lapply(x,
                   function(y)
                     pop_facts[
                       pop_facts[[pop]] %in% gsub(paste0(factors,collapse="|"),"",y),
                       gsub(paste0(pops,collapse="|"),"",y)
                     ]
            )
    )

  if(is.vector(fdata)){ fdata = matrix(fdata, nrow=1) }

  fdata_clean = vector(mode="list",length=dim(fdata)[2])

  for(l in 1:length(fdata_clean)){
    fdata_clean[[l]] = fdata[[l]]
    names(fdata_clean[[l]]) = gsub(paste0(pops,collapse="|"),"",t(relperms))[,l]
    fdata_clean[[l]] = c(fdata_clean[[l]], setNames(NA,facti))
  }

  # rates A/a
  .calcRF <- function(a){
    # sub in each pop rate for A/a

    fdata_cleanRF = fdata_clean
    for(l in 1:length(fdata_cleanRF)){
      fdata_cleanRF[[l]][facti] = list(a)
    }
    # calc F(a,...)
    rfunct = sapply(fdata_cleanRF, function(x) eval(parse(text = ratefunction), envir = as.list(x)))
    # calc QA/Qa
    if(is.null(dim(rfunct))){
      eq354 = aggregate(rfunct, by = list(eqp), FUN = sum)
      QAa = sum(eq354[,2]/eq354[,1])
    }else{
      eq354 = apply(rfunct, 1, function(x) aggregate(x, by = list(eqp), FUN = sum))
      QAa = sapply(eq354, function(x) sum(x[,2]/x[,1]))
    }
    return(QAa)
  }

  # popA/a rates
  if(nfact == 1){
    popAi = pop_facts[pop_facts[[pop]]==pops[1], facti]
    popBi = pop_facts[pop_facts[[pop]]==pops[2], facti]
  }else {
    popAi = .calcRF(  pop_facts[pop_facts[[pop]]==pops[1], facti]  )
    popBi = .calcRF(  pop_facts[pop_facts[[pop]]==pops[2], facti]  )
  }

  # a-effect
  diff=popBi-popAi

  res = data.frame(
    rate=c(popAi,popBi),
    pop=rep(pops,e=length(popAi)),
    std.set=rep(rev(pops),e=length(popAi)),
    diff=c(diff,-diff),
    diff.calc=rep(c(paste0(pops,collapse="-"),
                paste0(rev(pops),collapse="-")),e=length(popAi)),
    factor=facti
  )
  if(!is.null(id_vars) & length(popAi)>2){
    res <- as.data.frame(cbind(res, pop_facts[,id_vars,drop=FALSE]))
  }
  return(res)
}
