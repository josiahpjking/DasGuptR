eg4.4 <- data.frame(
  pop=rep(c(1963,1983),e=6),
  agegroup=c("15-19","20-24","25-29","30-34","35-39","40-44"),
  A = c(.200,.163,.146,.154,.168,.169,
        .169,.195,.190,.174,.150,.122),
  B = c(.866,.325,.119,.099,.099,.121,
        .931,.563,.311,.216,.199,.191),
  C = c(.007,.021,.023,.015,.008,.002,
        .018,.026,.023,.016,.008,.002),
  D = c(.454,.326,.195,.107,.051,.015,
        .380,.201,.149,.079,.025,.006)
)
# rate function
# sum(ABC) / (sum(ABC) + sum(A(1-B)D))
# crude rates
with(eg4.4[1:6,], sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D)) )
with(eg4.4[7:12,], sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D)) )

ratefunction="sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))"
tmpdf = as.data.frame(eg4.4)
pop = "pop"
factors = LETTERS[1:4]
tmpdf[[pop]] = factor(tmpdf[[pop]])
allpops = unique(tmpdf[[pop]])
nfact = length(factors)
id_vars = "agegroup"
subpop = interaction(tmpdf[,id_vars])
subpop = rep(1,nrow(tmpdf))
g=subpop[1]
tmpdf2 = tmpdf[subpop==g, ]
.makepopdf <- function(x){
  popdf = tmpdf2[tmpdf2[[pop]] %in% x, ]
  popdf[[pop]] = factor(popdf[[pop]], levels = x, ordered =T)
  popdf
}





pairwise_pops = combn(as.character(allpops), 2)
pw = apply(pairwise_pops, 2, \(x) .makepopdf(x))[[1]]
#nest data and extract factors


#### CHANGED
df_nested <- lapply(unique(pw[[pop]]), \(x) pw[pw[[pop]]==x, c(factors,id_vars,pop)])
names(df_nested) = unique(pw[[pop]])
df_nested


## crude rates


#lapply(factors, function(x) dg354(df_nested,x,factors,"xx*yy"))
facti=factors[1]
df2 = df_nested
pops=unique(names(df2))



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
          lapply(x,
                 function(y)
                   pop_facts[
                     # CHANGED
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
  fdata_clean[[l]] = c(fdata_clean[[l]], set_names(NA,facti))
}

fdata_clean

# MOST OF IT WILL CHANGE HERE!
.calcRF <- function(a){
  # sub in each pop rate for A/a

  # a = pop_facts[pop_facts[[pop]]==pops[1], facti]
  fdata_cleanRF = fdata_clean
  for(l in 1:length(fdata_cleanRF)){
    fdata_cleanRF[[l]][facti] = list(a) # changed
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


.calcRF(  pop_facts[pop_facts[[pop]]==pops[1], facti]  )
popBi = .calcRF(pop_facts[pops[2],facti])
