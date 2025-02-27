## ----setup, echo=FALSE,message=FALSE-------------------------------------
knitr::opts_chunk$set(message=FALSE, warning=FALSE)
require(kableExtra)

DasGupt_rates<-function(df){
  df %>%
    group_by(factor) %>%
    summarise_at(vars(starts_with("pop")),sum) %>% 
    gather(population,rate,starts_with("pop")) %>%
    mutate(population=gsub("pop","",population))
}

DasGupt_table<-function(DGdf,pop1,pop2){
  DasGupt_rates(DGdf) %>% filter(population %in% c(pop1,pop2)) %>%
    spread(population,rate) %>%
    mutate(difference=get(paste0(pop1))-get(paste0(pop2)))
}  


## ----packages------------------------------------------------------------
library(tidyverse)
library(DasGuptR)
data(reconv)
str(reconv)

## ----tib, echo=FALSE-----------------------------------------------------
tibble(
  Gender=c("Female","Male","All"),
  offenders=c(7842,41509,49351),
  reconvicted=c(2190,13787,15977),
  rate = reconvicted/offenders
) %>% kable(.,digits=3)

## ----wgtmean-------------------------------------------------------------
weighted.mean(x=c(.279,.332),w=c(7842,41509))

## ----tablerates, echo=FALSE----------------------------------------------
reconv %>% filter(year==2004) %>%
  group_by(Gender, convicted_population) %>% 
  summarise_at(vars(one_of(c("offenders","reconvicted","reconvictions"))),sum) %>%
  select(-reconvictions) %>%
  bind_rows(.,
            reconv %>% filter(year==2004) %>% 
              group_by(convicted_population) %>%
              summarise_at(vars(one_of(c("offenders","reconvicted","reconvictions"))),sum) %>% mutate(Gender="All") %>%
              select(-reconvictions)
  ) %>%
  mutate(
    prop_reconvicted = reconvicted/offenders,
    prop_offenders = offenders/convicted_population,
    crude_rate = prop_reconvicted*prop_offenders
  ) %>% select(Gender,offenders,reconvicted,convicted_population,prop_reconvicted, prop_offenders,crude_rate) %>%
  kable(.,digits=2) %>%
  row_spec(3, bold = T, color = "white", background = "#555555") %>%
  column_spec(7,bold=T)


## ----arpoexpl, echo=FALSE------------------------------------------------
reconv %>% filter(year==2004) %>%
  group_by(Gender, convicted_population) %>% 
  summarise_at(vars(one_of(c("offenders","reconvicted","reconvictions"))),sum) %>%
  bind_rows(.,
            reconv %>% filter(year==2004) %>% 
              group_by(convicted_population) %>%
              summarise_at(vars(one_of(c("offenders","reconvicted","reconvictions"))),sum) %>% mutate(Gender="All")
  ) %>%
  mutate(
    prop_reconvicted = reconvicted/offenders,
    prop_offenders = offenders/convicted_population,
    freq_reconvicted = reconvictions/reconvicted,
    crude_rate = prop_reconvicted*prop_offenders*freq_reconvicted
  ) %>% select(Gender,reconvicted,reconvictions,freq_reconvicted,prop_reconvicted, prop_offenders,crude_rate) %>% 
  kable(.,digits=2) %>%
  row_spec(3, bold = T, color = "white", background = "#555555") %>%
  column_spec(5,bold=T)


## ---- echo=FALSE---------------------------------------------------------
reconv %>% group_by(year) %>% 
  summarise_at(vars(one_of(c("offenders","reconvicted","reconvictions"))),sum) %>% 
  mutate(
    prevalence=round(reconvicted/offenders,3), 
    frequency=round(reconvictions/reconvicted,3)
  ) %>% select(year,prevalence,frequency,offenders,reconvicted,reconvictions) %>% 
  head %>% rbind(.,"...") %>% kable() %>%
  column_spec(1:3,bold=T,color="white",background = "#D7261E") %>%
  column_spec(4:6, color = "grey10") %>%
  add_header_above(c("Population" = 1, "Decomposition Factors" = 2, "Raw numbers" = 3),background="white",color="grey70")

## ---- echo=FALSE---------------------------------------------------------
reconv %>% 
  mutate(
    prevalence=round(reconvicted/offenders,3), 
    frequency=round(reconvictions/reconvicted,3),
    pop_str=round(offenders/convicted_population,3)
  ) %>% select(year,Gender,Age,prevalence,frequency,pop_str,offenders,reconvicted,reconvictions) %>% 
  head %>% rbind(.,"...") %>% kable() %>%
  column_spec(1:6,bold=T,color="white",background = "#D7261E") %>%
  column_spec(7:9, color = "grey10") %>%
  add_header_above(c("Population" = 1, "ID variables" = 2, "Decomposition factors" = 3, "Raw numbers" = 3),background="white",color="grey70")

## ----reconv_decomp, warning=FALSE,message=FALSE--------------------------
# create our decomposition factors
reconv <- 
  reconv %>% 
  mutate(
    prevalence = reconvicted/offenders,
    frequency = reconvictions/reconvicted, #not used here
    pop_str = offenders/convicted_population
  ) %>% 
  filter(year %in% 2004:2007) #the output is pretty cumbersome, so lets keep it at 4 years for now

#standardize and decompose!
reconv_DG <- DasGupt_Npop(df=reconv,
                          pop=year,
                          prevalence, pop_str,
                          id_vars=c(Age,Gender),
                          ratefunction="prevalence*pop_str")
                          # the default ratefunction calculates rate as the product of all specified factors
                          # in theory this function works with any function you like.

## ------------------------------------------------------------------------
str(reconv_DG)

## ----getrates------------------------------------------------------------
DasGupt_rates(reconv_DG)

## ------------------------------------------------------------------------
crude_rates <-
  reconv %>%
  mutate(rate=prevalence*pop_str) %>%
  group_by(year) %>% 
  summarise(
    rate=sum(rate),
    factor="crude"
  )

DasGupt_rates(reconv_DG) %>%
  mutate(year=as.numeric(population)) %>%
  bind_rows(., crude_rates) %>%  
  ggplot(.,aes(x=year,y=rate,col=factor))+geom_path()+theme_bw()+
  ylim(.3,.35)


## ------------------------------------------------------------------------
bind_rows(
  DasGupt_table(reconv_DG,2004,2007),
  crude_rates %>% filter(year %in% c(2004,2007)) %>%
    spread(year,rate) %>% mutate(difference=`2004`-`2007`)
) %>%
  mutate(percentage_of_unadjusted=100*(difference/difference[factor=="crude"])) %>%
  kable(.,digits=3)

## ------------------------------------------------------------------------
#reload the data
data(reconv)

reconv <- 
  reconv %>% 
  mutate(
    prevalence = reconvicted/offenders,
    frequency = reconvictions/reconvicted,
    pop_str = offenders/convicted_population
  ) 

reconv_DG <- DasGupt_Npop(df=reconv,
                          pop=year,prevalence, pop_str,frequency,
                          id_vars=c(Age,Gender),ratefunction="prevalence*pop_str*frequency")

crude_rates <-
  reconv %>%
  mutate(rate=prevalence*pop_str*frequency) %>%
  group_by(year) %>% 
  summarise(
    rate=sum(rate),
    factor="crude"
  )

DasGupt_rates(reconv_DG) %>%
  mutate(year=as.numeric(population)) %>%
  bind_rows(., crude_rates) %>%  
  ggplot(.,aes(x=year,y=rate,col=factor))+geom_path()+theme_bw()+
  theme(legend.position="bottom",axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(colour = guide_legend(nrow = 3, byrow = TRUE)) +
  labs(y = "avg number reconvs per offender",
       x = "Year")


