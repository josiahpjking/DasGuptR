library(tidyverse)
df <- DasGuptR::reconv |>
  janitor::clean_names() |>
  transmute(
    pop = year, sex, age,
    rate = prev_rate,
    size = offenders,
    r1 = rate*size,
    r0 = (1-rate)*size
  )


getBS <- function(){
  # expand out
  exp <- df |>
    select(pop,sex,age,r0,r1) |>
    pivot_longer(r0:r1, names_to="r",values_to = "n") |>
    mutate(n = as.integer(n)) |>
    uncount(n)

  # sample for each pop
  bs <- lapply(unique(df$pop), \(p)
               slice_sample(exp[exp$pop==p,],
                            prop=1,replace = TRUE) |>
                 group_by(sex,age) |>
                 summarise(
                   pop = p,
                   size = n(),
                   rate = mean(r=="r1")
                 ) |> ungroup())

  do.call(rbind,bs)
}


# 200 resamples
bsamps <-
  tibble(
    k = 1:200,
    i = map(1:200, ~getBS())
  )

# apply DG on each resample
bsamps <- bsamps |>
  mutate(
    dgo = map(i, ~dgnpop(., pop="pop",factors="rate",
                         id_vars=c("age","sex"),
                         crossclassified="size"))
  )

saveRDS(bsamps, "archive/bsamps500.RDS")

est = dgnpop(df,pop="pop",factors="rate",
             id_vars=c("age","sex"),crossclassified="size")$rates

# extract stuff!
bsamps |> mutate(
  rates = map(dgo,"rates"),
  diffs = map(dgo,"diffs")
) |> select(k, rates) |>
  unnest() |>
  mutate(pop=as.character(pop)) |>
  ggplot(aes(x = pop, y = rate, col = factor)) +
  geom_path(aes(group=interaction(factor,k)),alpha=1/10)+
  geom_path(data=est,aes(group=factor),lwd=1)





library(DasGuptR)
library(tidyverse)

eg.wang2000 <- data.frame(
  pop = rep(c("male","female"),e=12),
  ethnicity = rep(1:3,e=4),
  age_group = rep(1:4,3),
  size = c(
    130,1305,1539,316,211,697,334,48,105,475,424,49,
    70,604,428,43,55,127,44,9,72,178,103,12
  ),
  rate = c(
    12.31,34.90,52.91,44.44,16.67,36.40,51.20,41.67,12.38,19.20,21.23,12.50,
    17.14,35.55,48.71,55.81,14.55,39.37,32.56,55.56,22.22,20.34,13.59,8.33
  )
)


getBS <- function(){
  # expand out
  exp <- eg.wang2000 |>
    mutate(
      r1 = (rate/100)*size,
      r0 = (1-(rate/100))*size
    ) |>
    select(pop,ethnicity,age_group,r0:r1) |>
    pivot_longer(r0:r1, names_to="r",values_to = "n") |>
    mutate(n = as.integer(n)) |>
    uncount(n)

  # sample for each pop
  bs <- lapply(unique(eg.wang2000$pop), \(p)
               slice_sample(exp[exp$pop==p,],
                            prop=1,replace = TRUE) |>
                 group_by(ethnicity,age_group) |>
                 summarise(
                   pop = p,
                   size = n(),
                   rate = mean(r=="r1")*100
                 ) |> ungroup())

  do.call(rbind,bs)
}

# 200 resamples
bsamps <-
  tibble(
    k = 1:200,
    i = map(1:200, ~getBS())
  )

# apply DG on each resample
bsamps <- bsamps |>
  mutate(
    dgo = map(i, ~dgnpop(., pop="pop",factors="rate",
                         id_vars=c("ethnicity","age_group"),
                         crossclassified="size"))
  )

est = dgnpop(eg.wang2000,
       pop="pop",factors="rate",
       id_vars=c("ethnicity","age_group"),
       crossclassified = "size")

dgnpop(eg.wang2000,
       pop="pop",factors="rate",
       id_vars=c("ethnicity","age_group"),
       crossclassified = "size") |> dg_table()

# extract stuff!
bsamps |> select(k,dgo) |>
  unnest() |>
  group_by(k,factor) |>
  summarise(
    diff = diff(rate)
  ) |>
  group_by(factor) |>
  summarise(
    se = sd(diff)
  )


