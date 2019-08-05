require(tidyverse)
#require(DasGuptR)
map(list.files("R",full.names=T),source)
data(reconv)
head(reconv)

#this function basically expands our age/sex count data into binomial data (e.g. reconvicted 0/1)
#it then samples this data, and turns it back to group count data
Bs_samps<-function(x){
  #get 1 year
  df = x %>% mutate(nreconv = offenders-reconvicted)

  #original data, in long form
  odata<-
    tibble(
      Sex=c(rep(df$Sex,df$reconvicted),rep(df$Sex,df$nreconv)),
      Age=c(rep(df$Age,df$reconvicted),rep(df$Age,df$nreconv)),
      reconv=c(rep(1,sum(df$reconvicted)),rep(0,sum(df$nreconv)))
    )

  #sample function
  samp <- odata[sample(1:nrow(odata),replace=T),] %>%
    group_by(Sex,Age) %>%
    summarise(
      reconvicted=sum(reconv),
      offenders=n()
    ) %>% ungroup %>%
    mutate(
      prevalence = reconvicted/offenders,
      convicted_population = sum(offenders),
      pop_str = offenders/convicted_population
    )
  samp
}

#i.e. the following code provides us with one sample
map_dfr(unique(reconv$year),~filter(reconv,year==.x) %>% Bs_samps %>% mutate(year=.x))

#set R for bootstrapping
bs_r = 200

#create bootstrapping samples, and then standardize & decompose them (takes ages!)
#13 populations, 10 subgroup breakdowns, takes approx 5mins per 10 bootstrap samples
#Ideally we want c200 (see Wang, Rahman, Siegal and Fisher 2000.)
system.time(
  bs_ALLsamples <-
    tibble(
      sampledata = map(1:bs_r, ~map_dfr(unique(reconv$year),~filter(reconv,year==.x) %>% Bs_samps %>% mutate(year=.x))),
      dg = map(sampledata, ~DasGupt_Npop(.,pop=year,prevalence,pop_str,id_vars=c(Age,Sex),ratefunction="prevalence*pop_str"))
  )
)
#saveRDS(bs_ALLsamples, "archive/bootstrappedr200.RDS")
#bs_ALLsamples <- readRDS("archive/bootstrappedr50.RDS")

#pull the rates for each sample,
rateSD <-
  bs_ALLsamples %>%
  mutate(
    pops=map(dg, DasGupt_rates) #this function extracts the rates from the DasGupt_Npop() output
  ) %>% pull(pops) %>%
  bind_rows() %>%
  group_by(factor,population) %>%
  summarise(sdrate=sd(rate))

reconv %>%
  mutate(prevalence=reconvicted/offenders, pop_str=offenders/convicted_population) %>%
  DasGupt_Npop(.,pop=year,prevalence,pop_str,id_vars=c(Age,Sex),ratefunction="prevalence*pop_str") -> DGreconv

crude_rates <-
  reconv %>% mutate(prevalence=reconvicted/offenders, pop_str=offenders/convicted_population) %>%
  mutate(rate=prevalence*pop_str) %>%
  group_by(year) %>%
  summarise(
    rate=sum(rate),
    factor="crude"
  ) %>% mutate(population=as.character(year)) %>% select(-year)

DasGupt_rates(DGreconv) %>%
  left_join(.,
            rateSD
  ) %>%
  mutate(low=rate-(1.96*sdrate),
         high=rate+(1.96*sdrate)
  ) %>%
  bind_rows(., crude_rates) %>%
  ggplot(.,aes(x=population,y=rate,col=factor,group=factor))+
  geom_path()+
  geom_ribbon(aes(ymin=low,ymax=high,fill=factor),col=NA,alpha=.2)+
  theme_bw()+
  scale_color_manual(values = c("black","#1b9e77","#d95f02"))+
  scale_fill_manual(values = c("black","#1b9e77","#d95f02"))+
  NULL

#

bs_diffs <- function(x){
  x %>% group_by(factor) %>%
    summarise_at(vars(starts_with("diff")),sum) %>% gather(diff,effect,starts_with("diff"))
}

bs_ALLsamples %>%
  mutate(
    diffs=map(dg, bs_diffs)
  ) %>% pull(diffs) %>%
  bind_rows() -> diffs

qqnorm(diffs$effect[diffs$factor=="prevalence"])
qqnorm(diffs$effect[diffs$factor=="prevalence" & diffs$diff=="diff2004_2005"])

