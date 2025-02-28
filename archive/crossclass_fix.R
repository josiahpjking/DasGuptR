#library(DasGuptR)
eg5.3 <- data.frame(
  race = rep(rep(1:2, e=11),2),
  age = rep(rep(1:11,2),2),
  pop = rep(c(1985,1970), e=22),
  size = c(3041,11577,27450,32711,35480,27411,19555,19795,15254,8022,2472,
           707,2692,6473,6841,6547,4352,3034,2540,1749,804,236,
           2968,11484,34614,30992,21983,20314,20928,16897,11339,5720,1315,
           535,2162,6120,4781,3096,2718,2363,1767,1149,448,117),
  rate = c(9.163,0.462,0.248,0.929,1.084,1.810,4.715,12.187,27.728,64.068,157.570,
           17.208,0.738,0.328,1.103,2.045,3.724,8.052,17.812,34.128,68.276,125.161,
           18.469,0.751,0.391,1.146,1.287,2.672,6.636,15.691,34.723,79.763,176.837,
           36.993,1.352,0.541,2.040,3.523,6.746,12.967,24.471,45.091,74.902,123.205)
)

dgnpop(eg5.3, pop = "pop", factors=c("rate"), id_vars = c("race","age"),
       ratefunction="rate")

dgnpop(eg5.3, pop = "pop", factors=c("rate"), id_vars = c("race","age"),
       crossclassified = "size", ratefunction = "rate")

dgnpop(eg5.3, pop = "pop", factors=c("rate"), id_vars = c("race","age"),
       crossclassified = "size", ratefunction = "sum(rate)")



tmpdf<-eg5.3
pop="pop"
id_vars=c("race","age")
factors="rate"
crossclassified="size"
quietly=TRUE


tmpdf[[pop]] = factor(tmpdf[[pop]])
allpops = unique(tmpdf[[pop]])
nfact = length(factors)
.makepopdf <- function(x){
  popdf = tmpdf[tmpdf[[pop]] %in% x, ]
  popdf[[pop]] = factor(popdf[[pop]], levels = x, ordered =T)
  popdf
}
pairwise_pops = combn(as.character(allpops), 2)
pairwise_est = apply(pairwise_pops, 2, \(x) .makepopdf(x))

# 1. join rates from dgo w tmpdf
# 2. group T+t/2 and p+P/2
# 3. dgcc > dgo w struct as factors
# 4. T+t/2 * each output from 3
# 5. p+P/2 * r

rr1 = dg2pop(pairwise_est[[1]],
       pop=pop,factors="rate",id_vars=id_vars,
       ratefunction="rate", quietly=quietly)
ss1 = dg2pop(pairwise_est[[1]],
             pop=pop,factors="size",id_vars=id_vars,
             ratefunction="size/sum(size)", quietly=quietly)
rr1 = do.call(rbind,rr1)
ss1 = do.call(rbind,ss1)

rr1$tt2 = with(rr1, (rate + (rate+diff)) / 2)
ss1$nn2 = with(ss1, (rate + (rate+diff)) / 2)

rr1$rate_adj = rr1$rate * ss1$nn2

aar = dg2pop(dgcc(pairwise_est[[1]], pop=pop, id_vars = id_vars, crossclassified = crossclassified),
       pop=pop,
       factors=paste0(id_vars,"_struct"),
       id_vars=id_vars,
       ratefunction=paste0(paste0(id_vars,"_struct"), collapse="*"),
       quietly=quietly)

rrr = cbind(
  rr1,
  do.call(cbind, lapply(aar, \(x) x[['rate']]*rr1$tt2))
)
rrr |> group_by(pop) |> summarise(
  rate = sum(rate_adj),
  race_struct = sum(race_struct),
  age_struct = sum(age_struct)
) |> as.data.frame()

