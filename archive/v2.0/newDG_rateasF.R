lapply(list.files("R/",full.names = T),source)
data(reconv)
require(tidyverse)
load("data/reconv.RData")
DG_reconv <- DasGupt_Npop(reconv,
                          pop=year,
                          prevalence, age_str,
                          id_vars=c(Age,Gender)
)



df2<-reconv %>% filter(year %in% c(2005,2006))
factrs=c("prevalence","frequency","age_str")
nfact=length(factrs)
df2$pop<-df2$year
#nest and make factor matrix
df2 %>% group_by(pop) %>%
  nest() %>%
  mutate(
    factor_df = map(data, magrittr::extract,factrs)
  ) -> df_nested

#the get_effect function will loop over the indices of your factors, and for
#each factor A, it will get the BCD... adjusted rates for each population, and
#spit out the difference too.
#equivalent to Q1, Q2, ....  in Ben's function
decomp_out<-map(1:nfact,~DGadjust_ratefactor(df_nested,pop,.,factrs))
names(decomp_out)<-factrs

df2<-df_nested
i=1
####################
#DGadjust_ratefactor
##
splitAt <- function(x, pos) unname(split(x, cumsum(seq_along(x) %in% pos)))
#how many factors?
nfact=length(factrs)

#these are all the population factors (for both populations), spread.
#this means that indices 1:n/2 are pop1, and n/2:n are pop2.
pop_facts<-df2 %>% dplyr::select(pop,factor_df) %>% spread(pop,factor_df) %>% unnest()

#this is the alpha
facti="prevalence"


allfacts=names(pop_facts)

allperms<-combn(allfacts[!(allfacts %in% c(facti,paste0(facti,1)))],length(allfacts)/2-1) %>% t %>% as_tibble()

count1s <- apply(allperms, 1, function(x) length(which(grepl("1",x))))
count0s <- apply(allperms, 1, function(x) length(which(!grepl("1",x))))
countmult <- apply(map_df(allperms,~gsub("1","",.)), 1, function(x) sum(duplicated(x)|duplicated(x, fromLast = TRUE)))

allperms %>% mutate(
  c1s=ifelse(count1s %in% c(0,(length(allfacts)/2-1)),0,count1s),
  c0s=ifelse(count0s %in% c(0,(length(allfacts)/2-1)),0,count0s),
  cMs=countmult
) %>% filter(cMs==0) -> allperms

allperms$f_id<-paste0("f",1:nrow(allperms))
eq_parts <-
  allperms %>% group_by(c0s,c1s) %>%
  summarise(
    n=n(),
    F_eqs=list(f_id)
  ) %>% ungroup

denominators = map_dbl(1:nrow(eq_parts)-1,~nfact*(ncol(combn(nfact-1,.))))

allperms <- allperms %>% as_tibble %>%
  mutate(
    data=map(1:nrow(allperms),~pop_facts[allfacts[allfacts %in% c(facti,allperms[.,1:((length(allfacts)/2)-1)])]]),
    data1=map(1:nrow(allperms),~pop_facts[allfacts[allfacts %in% c(paste0(facti,1),allperms[.,1:((length(allfacts)/2)-1)])]])
  )

rate_function="prevalence*frequency*age_str"
colClean <- function(x){ colnames(x) <- gsub("1", "", colnames(x)); x }
#map the rate function on to the data column
allperms %>% mutate(
  data_rn = map(data,colClean),
  rfunct = map(data_rn,~mutate(.,rf=eval(parse(text=rate_function))) %>% pull(rf)),

  data1_rn = map(data1,colClean),
  rfunct1 = map(data1_rn,~mutate(.,rf=eval(parse(text=rate_function))) %>% pull(rf))
) %>% select(-c(data,data_rn,cMs,data1,data1_rn)) -> allperms

eq_parts
#spred, unnest
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

tibble(
  !!paste0("pop",df2 %>% pull(pop) %>% .[1] %>% as.character):=eq_parts %>% select(eq) %>% unlist(recursive = F) %>% as_tibble() %>% rowSums,
  !!paste0("pop",df2 %>% pull(pop) %>% .[2] %>% as.character):=eq_parts %>% select(eq1) %>% unlist(recursive = F) %>% as_tibble() %>% rowSums
)



#group by number of 0/1s

#sum

#join denominators

extract A,
do the combinations bit
add in A
do the function bit.






#DG's formula on p15 requires all different permutations of sets of all factors where factors are taken from either population.
#I figured the easiest way to do this might be to use permutations of column indices in pop_facts
nfact=5
r=ceiling(nfact/2)-1
all_perms=map(1:r,~unique(c(combinat::permn(c(rep(1,nfact-1-.x),rep(2,.x))), combinat::permn(c(rep(2,nfact-1-.x),rep(1,.x))))))
colnums=all_perms %>% unlist(.,recursive=F) %>% map(.,~c(which(.x>1)+(nfact-1),which(.x<2)))



map_dbl(1:length(length_perms),~nfact*(ncol(utils::combn(nfact-1,.))))

#relevant later
length_perms = map_dbl(all_perms,length)
denominators=map_dbl(1:length(length_perms),~nfact*(ncol(utils::combn(nfact-1,.))))


pop_facts
#extract values, calculate products
tibble(
    #these are translating the all_perms values into column indices
colnums = colnums,
  # how many combinations are there? (these are the denominators for DG formula)
colcombs = rep(length_perms,times=length_perms),
  # factor values
fact_vals = map(colnums,~pop_facts[,.x]),
# as matrix and rowProduct
fact_valsm = map(fact_vals,as.matrix),
prods = map(fact_valsm,matrixStats::rowProds,na.rm=T)
) %>% pull(fact_vals) %>% print #%>% as_tibble(.,.name_repair="universal")

  map(splitAt(1:ncol(prod_tibs),cumsum(length_perms+1)), ~prod_tibs[.x]) %>%
    map(.,rowSums,na.rm=T) %>%
    map2_dfc(.,denominators, ~(.x/.y)) %>%
    #as_tibble(.,.name_repair="universal") %>%
    #add in the first part of the equation (abcd+ABCD)
    mutate(
      p0=qdf %>% dplyr::select(!!pop,pop_prod) %>%
        spread(!!pop,pop_prod) %>%
        unnest %>%
        rowSums(.,na.rm=T) %>%
        map2_dbl(.,nfact,~(.x/.y))
    ) -> sum_prods
}
#extract alpha and multiply by Q
qdf %>% dplyr::select(!!pop,alpha) %>% spread(!!pop,alpha) %>% unnest %>%
  map(.,~.x*rowSums(sum_prods,na.rm=T)) -> effects

tibble(
  !!paste0("pop",qdf %>% pull(!!pop) %>% .[1] %>% as.character):=effects[[2]],
  !!paste0("pop",qdf %>% pull(!!pop) %>% .[2] %>% as.character):=effects[[1]],
  factoreffect=effects[[2]]-effects[[1]]
)


