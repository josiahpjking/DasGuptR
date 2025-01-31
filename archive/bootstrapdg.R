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





