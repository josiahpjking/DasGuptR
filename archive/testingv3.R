library(tidyverse)
load("data/reconv.RData")
lapply(list.files("R/",full.names=T),\(x) source(x))
rr1 = reconv <-
  reconv |>
  mutate(
    prevalence = reconvicted/offenders,
    frequency = reconvictions/reconvicted, #not used here
    pop_str = offenders/convicted_population
  ) |>
  filter(year %in% c(2004:2006))


dd = dgnpop(rr1,pop="year",c("prevalence","pop_str"),id_vars = c("Age","Sex"))
dg_rates(dd)
dg_table(dd, pop1 = 2004,pop2=2006)

dgnpop(rr1,pop="year",c("prevalence","pop_str"),id_vars = c("Age","Sex"))

dgnpop(rr1[rr1$year!=2005,],pop="year",c("prevalence","pop_str"),id_vars = c("Age","Sex"))

dgnpop(rr1,"year",c("prevalence","pop_str","frequency"),id_vars = c("Age","Sex"))
dgnpop(rr1[rr1$year!=2005,],"year",c("prevalence","pop_str","frequency"),id_vars = c("Age","Sex"))



# The case of 2 factors (2 populations)
eg2.1 <- data.frame(
  pop = c("black","white"),
  avg_earnings = c(10930, 16591),
  earner_prop = c(.717892, .825974)
)
dgnpop(eg2.1, pop="pop",factors=c("avg_earnings", "earner_prop")) |>
#  print() |>
  dg_rates()


# The case of 3 factors (2 populations)
eg2.3 <- data.frame(
  pop = c("austria","chile"),
  birthsw1549 = c(51.78746, 84.90502),
  propw1549 = c(.45919, .75756),
  propw = c(.52638, .51065)
)
dgnpop(eg2.3, pop="pop", factors=c("birthsw1549", "propw1549", "propw")) |>
  print() |>
  dg_rates()

# The case of 4 factors (2 populations)
eg2.5 <- data.frame(
  pop = c(1971, 1979),
  birth_preg = c(25.3, 32.7),
  preg_actw = c(.214, .290),
  actw_prop = c(.279, .473),
  w_prop = c(.949, .986)
)
dgnpop(eg2.5, pop="pop", c("birth_preg", "preg_actw", "actw_prop", "w_prop")) |>
  print() |>
  dg_rates()

# The case of 5 factors (2 populations)
eg2.7 <- data.frame(
  pop = c(1970, 1980),
  prop_m = c(.58, .72),
  noncontr = c(.76, .97),
  abort = c(.84, .97),
  lact = c(.66, .56),
  fecund = c(16.573, 16.158)
)
dgnpop(eg2.7, pop="pop", c("prop_m", "noncontr", "abort", "lact", "fecund")) |>
  print() |>
  dg_rates()

# The case of 3 vector factors (2 populations)
eg4.5 <- data.frame(
  agegroup = rep(1:7, 2),
  pop = rep(c(1970, 1960), e = 7),
  bm = c(488, 452, 338, 156, 63, 22, 3,
         393, 407, 369, 274, 184, 90, 16),
  mw = c(.082, .527, .866, .941, .942, .923, .876,
         .122, .622, .903, .930, .916, .873, .800),
  wp = c(.058, .038, .032, .030, .026, .023, .019,
         .043, .041, .036, .032, .026, .020, .018)
)
dgnpop(eg4.5, pop="pop", c("bm", "mw", "wp"), id_vars=c("agegroup")) |>
  print() |>
  dg_rates() |>
  dg_table(pop1=1960,pop2=1970)



eg3.1 <- data.frame(
  pop = c(1940,1960),
  crude_birth = c(19.4, 23.7),
  crude_death = c(10.8, 9.5)
)
eg3.1$crude_NI <- eg3.1$crude_birth - eg3.1$crude_death
dgnpop(eg3.1, pop="pop",c("crude_birth","crude_death"),
       ratefunction = "crude_birth-crude_death") |> dg_rates()


eg4.1 <- data.frame(
  age_group = c("10-15","15-20","20-25","25-30","30-35","35-40","40-45","45-50","50-55"),
  pop=rep(c(1965,1960),e=9),
  Lx=c(486446,485454,483929,482046,479522,475844,470419,462351,450468,
       485434,484410,492905,481001,478485,474911,469528,461368,449349),
  mx=c(.00041,.03416,.09584,.07915,.04651,.02283,.00631,.00038,.00000,
       .00040,.04335,.12581,.09641,.05504,.02760,.00758,.00045,.00001)
)
## WTF?




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


dgnpop(eg4.4, pop="pop",factors=c("A","B","C","D"), id_vars = "agegroup") |>
  pivot_wider(names_from=factor,values_from=adj.rate)


