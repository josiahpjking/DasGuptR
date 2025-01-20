
# remotes::install_github("josiahpjking/DasGuptR@develop")
# library(DasGuptR)

# - alternative to rlang::set_names in 354
# - for 2 pop only, remove diffs -- DONE
# - remove dg_rates, fix dg_table -- DONE
# - make dg_table a dataframe rather than xtabs, but preserve structure
# - figure out the decomp effects in N pops.. not quite working..



# 2 factors, 2 populations, R=ab
eg2.1 <- data.frame(
  pop = c("black","white"),
  avg_earnings = c(10930, 16591),
  earner_prop = c(.717892, .825974)
)
dgnpop(eg2.1, pop="pop",factors=c("avg_earnings", "earner_prop")) |>
  #print() |>
  dg_table()



# 3 factors, 2 populations, R=abc
eg2.3 <- data.frame(
  pop = c("austria","chile"),
  birthsw1549 = c(51.78746, 84.90502),
  propw1549 = c(.45919, .75756),
  propw = c(.52638, .51065)
)
dgnpop(eg2.3, pop="pop", factors=c("birthsw1549", "propw1549", "propw")) |>
  #print() |>
  dg_table()

# 4 factors, 2 populations, R=abcd
eg2.5 <- data.frame(
  pop = c(1971, 1979),
  birth_preg = c(25.3, 32.7),
  preg_actw = c(.214, .290),
  actw_prop = c(.279, .473),
  w_prop = c(.949, .986)
)
dgnpop(eg2.5, pop="pop", c("birth_preg", "preg_actw", "actw_prop", "w_prop")) |>
  #print() |>
  dg_table()

# 5 factors, 2 populations, R=abcde
eg2.7 <- data.frame(
  pop = c(1970, 1980),
  prop_m = c(.58, .72),
  noncontr = c(.76, .97),
  abort = c(.84, .97),
  lact = c(.66, .56),
  fecund = c(16.573, 16.158)
)
dgnpop(eg2.7, pop="pop", c("prop_m", "noncontr", "abort", "lact", "fecund")) |>
  #print() |>
  dg_table()


# 2 factors, 2 populations, R=f(a,b)
eg3.1 <- data.frame(
  pop = c(1940,1960),
  crude_birth = c(19.4, 23.7),
  crude_death = c(10.8, 9.5)
)
# crude rates
eg3.1$crude_birth - eg3.1$crude_death

dgnpop(eg3.1, pop="pop",c("crude_birth","crude_death"),
       ratefunction = "crude_birth-crude_death") |>
  #print() |>
  dg_table()


# 3 vector factors, 2 populations, R=sum(ABC)
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
dgnpop(eg4.5, pop="pop", c("bm", "mw", "wp"),
       id_vars=c("agegroup"),ratefunction = "sum(bm*mw*wp)") |>
  #print() |>
  dg_table()

# in simple cases like this, we can equivalently run DG on each individual subpopulation,
# and then aggregate up
library(tidyverse)
eg4.5 |> nest(data=-agegroup) |>
  mutate(
    dg = map(data, ~ dgnpop(., pop="pop",factors=c("bm","mw","wp")))
  ) |> unnest(dg) |>
  group_by(pop,factor) |>
  summarise(
    rate = sum(rate)
  )


# 4 vector factors, 2 populations, R=f(A,B)
# rate as function of vector factors
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
# rate function of
# sum(ABC) / (sum(ABC) + sum(A(1-B)D))
# crude rates
with(eg4.4[1:6,], sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D)) )
with(eg4.4[7:12,], sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D)) )

dgnpop(eg4.4, pop="pop",factors=c("A","B","C","D"), id_vars = "agegroup",
       ratefunction="sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))") |>
  #print() |>
  dg_table()


# alternatively:
myratef <- function(a,b,c,d){
  return( sum(a*b*c) / (sum(a*b*c) + sum(a*(1-b)*d))  )
}
dgnpop(eg4.4, pop="pop",factors=c("A","B","C","D"), id_vars = "agegroup",
       ratefunction="myratef(A,B,C,D)")




eg4.1 <- data.frame(
  age_group = c("10-15","15-20","20-25","25-30","30-35","35-40","40-45","45-50","50-55"),
  pop=rep(c(1965,1960),e=9),
  Lx=c(486446,485454,483929,482046,479522,475844,470419,462351,450468,
       485434,484410,492905,481001,478485,474911,469528,461368,449349),
  mx=c(.00041,.03416,.09584,.07915,.04651,.02283,.00631,.00038,.00000,
       .00040,.04335,.12581,.09641,.05504,.02760,.00756,.00045,.00000)
)
## WTF?

RF4.1 <- function(A,B){
  idx = 1:length(A)
  mu0 = sum(A*B/100000)
  mu1 = sum((5*idx + 7.5)*A*B/100000)
  r1 = log(mu0) * (mu0/mu1)
  while(TRUE){
    Nr1 = 0
    Dr1 = 0
    Nr1 = Nr1 + sum(exp(-r1 * (5*idx + 7.5)) * A * (B / 100000))
    Dr1 = Dr1 - sum((5*idx + 7.5) * exp(-r1 * (5*idx + 7.5)) * A * (B / 100000))
    r2 = r1 - ((Nr1 - 1)/Dr1)
    if(abs(r2 - r1)<=.0000001){
      break
    }
    r1 = r2
  }
  return(r2)
}
RF4.1(A = eg4.1$Lx[1:9], B = eg4.1$mx[1:9])
RF4.1(A = eg4.1$Lx[10:18], B = eg4.1$mx[10:18])

dgnpop(eg4.1, pop="pop",factors=c("Lx","mx"), id_vars = "age_group",
       ratefunction="RF4.1(Lx,mx)")


eg5.1 <- data.frame(
  age_group = rep(c("15-19","20-24","25-29","30-34","35-39",
                "40-44","45-49","50-54","55-59","60-64",
                "65-69","70-74","75+"),2),
  pop = rep(c(1970,1985),e=13),
  size = c(12.9,10.9,9.5,8.0,7.8,8.4,8.6,7.8,7.0,5.9,4.7,3.6,4.9,
           10.1,11.2,11.6,10.9,9.4,7.7,6.3,6.0,6.3,5.9,5.1,4.0,5.5),
  rate = c(1.9,25.8,45.7,49.6,51.2,51.6,51.8,54.9,58.7,60.4,62.8,66.6,66.8,
           2.2,24.3,45.8,52.5,56.1,55.6,56.0,57.4,57.2,61.2,63.9,68.6,72.2)
)

dgnpop(eg5.1, pop="pop",factors=c("size","rate"), id_vars = "age_group",
       ratefunction="sum((size/100)*rate)") |>
  dg_table() |> round(3)

eg5.1$age_str <- eg5.1$size/100

dgnpop(eg5.1, pop="pop",factors=c("age_str","rate"), id_vars = "age_group",
       ratefunction="sum(age_str*rate)") |>
  dg_table() |> round(3)


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

dgnpop(eg5.3, pop = "pop", factors=c("size","rate"), id_vars = c("race","age"),
       ratefunction = "sum( size/sum(size)*rate)") |>
  dg_table() |> round(3)

dgnpop(eg5.3, pop = "pop", factors=c("rate"), id_vars = c("race","age"),
       crossclassified = "size") |>
  dg_table() |> round(3)


library(tidyverse)
eg5.3a <- eg5.3 |>
  group_by(pop) |> mutate(n_tot = sum(size)) |>
  group_by(pop,age) |> mutate(n_age = sum(size)) |>
  group_by(pop,race) |> mutate(n_race = sum(size)) |>
  ungroup() |>
  mutate(
    A = ((size / n_race) * (n_age / n_tot))^(1/2),
    B = ((size / n_age) * (n_race / n_tot))^(1/2),
    AB = A*B, # same as:
    prop = size/n_tot
  )

dgnpop(eg5.3a, pop = "pop", factors=c("A","B","rate"), id_vars = c("race","age"),
       ratefunction = "sum( (A*B*rate)/sum(A*B) )") |>
  dg_table() |> round(3)


split_popstr(eg5.3[eg5.3$pop==1985,], id_vars=c("age","race"),nvar="size") |>
  head()

dgnpop(eg5.3, pop = "pop", factors=c("rate"), id_vars = c("race","age"),
       crossclassified = "size") |>
  dg_table() |> round(3)






# 4 vector factors, 5 populations, R=f(A,B)
# rate as function of vector factors
eg6.6 <- data.frame(
  pop=rep(c(1963,1968,1973,1978,1983),e=6),
  agegroup=c("15-19","20-24","25-29","30-34","35-39","40-44"),
  A = c(.200,.163,.146,.154,.168,.169,
        .215,.191,.156,.137,.144,.157,
        .218,.203,.175,.144,.127,.133,
        .205,.200,.181,.162,.134,.118,
        .169,.195,.190,.174,.150,.122),
  B = c(.866,.325,.119,.099,.099,.121,
        .891,.373,.124,.100,.107,.127,
        .870,.396,.158,.125,.113,.129,
        .900,.484,.243,.176,.155,.168,
        .931,.563,.311,.216,.199,.191),
  C = c(.007,.021,.023,.015,.008,.002,
        .010,.023,.023,.015,.008,.002,
        .011,.016,.017,.011,.006,.002,
        .014,.019,.015,.010,.005,.001,
        .018,.026,.023,.016,.008,.002),
  D = c(.454,.326,.195,.107,.051,.015,
        .433,.249,.159,.079,.037,.011,
        .314,.181,.133,.063,.023,.006,
        .313,.191,.143,.069,.021,.004,
        .380,.201,.149,.079,.025,.006)
)
eg6.6 |> group_by(pop) |>
  summarise(
    crude = sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))
  )

dgnpop(eg6.6, pop="pop",factors=c("A","B","C","D"),id_vars="agegroup",
       ratefunction="1000*sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))")$rates  |> select(-std.set) |>
  pivot_wider(names_from=pop,values_from=rate)

dgnpop(eg6.6, pop="pop",factors=c("A","B","C","D"),id_vars="agegroup",
       ratefunction="1000*sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))")$diffs |>
  select(-pop,-std.set) |>
  pivot_wider(values_from=diff,names_from=diff.calc)



eg6.12 <- read_csv("archive/uspop_dg.csv") |>
  group_by(year) |>
  mutate(
    totalpop = sum(thous),
    pop_str=thous/totalpop
  ) |> ungroup()

dd <- dgnpop(eg6.12, pop="year",factors=c("pop_str","birthrate"),
       ratefunction = "sum(pop_str*birthrate)",
       id_vars="agebin")
dd$rates |> select(-adj.set) |>
  pivot_wider(values_from=rate,names_from=factor)
