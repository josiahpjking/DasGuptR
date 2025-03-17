## -----------------------------------------------------------------------------
knitr::opts_chunk$set(
  message=FALSE,
  warning=FALSE
)

## -----------------------------------------------------------------------------
library(DasGuptR)
library(tidyverse)
library(gt)

## -----------------------------------------------------------------------------
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

## -----------------------------------------------------------------------------
dgnpop(eg5.3, pop = "pop", factors = "rate", 
       id_vars = c("race", "age"), crossclassified = "size") |>
  dg_table()

## -----------------------------------------------------------------------------
res <- dgnpop(eg5.3, pop = "pop", factors="rate",
              id_vars = c("race","age"), crossclassified = "size", agg = FALSE)
head(res)

## -----------------------------------------------------------------------------
res |>
  pivot_wider(names_from = factor, values_from = rate)

## -----------------------------------------------------------------------------
race_ce <- res |>
  pivot_wider(names_from = factor, values_from = rate) |>
  group_by(pop,race) |>
  summarise(
    # sum of P-I std rates
    IAi = sum(race_struct),
    # sum of P-T std rates / number of crossclass vars
    RTi = sum(rate)*(1/2),
    CEi = IAi+RTi
  ) |>
  group_by(race) |>
  summarise(
    # category composition effect
    comp_ce = IAi[pop==1985] - IAi[pop==1970],
    # category rate effect
    rate_ce = RTi[pop==1985] - RTi[pop==1970],
    # category total effect
    tot_ce = CEi[pop==1985] - CEi[pop==1970]
  )

## -----------------------------------------------------------------------------
age_ce <- res |>
  pivot_wider(names_from = factor, values_from = rate) |>
  group_by(pop, age) |>
  summarise(
    # sum of P-J std rates
    JBj = sum(age_struct),
    # sum of P-T std rates / number of crossclass vars
    RTj = sum(rate)*(1/2),
    CEj = JBj+RTj
  ) |>
  group_by(age) |>
  summarise(
    # category composition effect
    comp_ce = JBj[pop==1985] - JBj[pop==1970],
    # category rate effect
    rate_ce = RTj[pop==1985] - RTj[pop==1970],
    # category total effect
    tot_ce = CEj[pop==1985] - CEj[pop==1970]
  )

## -----------------------------------------------------------------------------
sum( c(race_ce$tot_ce, age_ce$tot_ce) )

## -----------------------------------------------------------------------------
sum( c(race_ce$rate_ce, age_ce$rate_ce) )

## -----------------------------------------------------------------------------
bind_rows(
  race_ce |> mutate(var = "race") |> rename(category = race),
  age_ce |> mutate(var = "age") |> rename(category = age)
) |> 
  mutate(
    comp_ce = comp_ce/sum(tot_ce)*100,
    rate_ce = rate_ce/sum(tot_ce)*100,
    tot_ce = tot_ce/sum(tot_ce)*100
  ) |>
  group_by(var) |> 
  mutate(across(2:4, ~round(.,2))) |>
  gt()

## -----------------------------------------------------------------------------
eg5.3 |> group_by(pop, age) |> 
  summarise(size = sum(size)) |> 
  group_by(pop) |> 
  mutate(prop = size/sum(size)) |> 
  group_by(age) |> 
  summarise(delta = prop[pop==1985] - prop[pop==1970])

## -----------------------------------------------------------------------------
data(reconv)
srec <- reconv |> filter(year %in% c(2004,2016)) |>
  select(year, Sex, Age, offenders, prev_rate)

## -----------------------------------------------------------------------------
 dgnpop(srec, pop = "year", factors = c("prev_rate"),
              id_vars = c("Age","Sex"),
              crossclassified = "offenders", agg = TRUE) |>
  dg_table()

## -----------------------------------------------------------------------------
res <- dgnpop(srec, pop = "year", factors = c("prev_rate"),
              id_vars = c("Age","Sex"),
              crossclassified = "offenders", agg = FALSE)

## -----------------------------------------------------------------------------
sex_ce <- res |>
  pivot_wider(names_from = factor, values_from = rate) |>
  group_by(pop, Sex) |>
  summarise(
    IAi = sum(Sex_struct),
    RTi = sum(prev_rate)*(1/2),
    CEi = IAi+RTi
  ) |>
  group_by(Sex) |>
  summarise(
    comp_ce = diff(IAi),
    rate_ce = diff(RTi),
    tot_ce = diff(CEi)
  )

age_ce <- res |>
  pivot_wider(names_from = factor, values_from = rate) |>
  group_by(pop, Age) |>
  summarise(
    JBj = sum(Age_struct),
    RTj = sum(prev_rate)*(1/2),
    CEj = JBj+RTj
  ) |>
  group_by(Age) |>
  summarise(
    comp_ce = diff(JBj),
    rate_ce = diff(RTj),
    tot_ce = diff(CEj)
  )

## -----------------------------------------------------------------------------
bind_rows(
  sex_ce |> mutate(var = "sex") |> rename(category = Sex),
  age_ce |> mutate(var = "age") |> rename(category = Age)
) |> 
  mutate(
    comp_ce = comp_ce/sum(tot_ce)*100,
    rate_ce = rate_ce/sum(tot_ce)*100,
    tot_ce = tot_ce/sum(tot_ce)*100
  ) |>
  group_by(var) |> 
  mutate(across(2:4, ~round(.,2))) |>
  gt()

