require(tidyverse)
require(readxl)

#https://www.census.gov/data/tables/time-series/demo/popest/pre-1980-national.html
usdat_sheet<-function(i,x){
  df = read_xls(paste0("C:/Users/jking34/Downloads/pe-11-",x,"s.xls"),sheet=i+1)
  df = df[,1:4]
  df = na.omit(df)
  names(df) = c("age","num","male","female")
  df = filter(df, age!="All ages")
  df = df %>% mutate(source=x+i)
}

uspops<-
  bind_rows(
    map_dfr(0:9,~usdat_sheet(.,1940)),
    map_dfr(0:9,~usdat_sheet(.,1950)),
    map_dfr(0:9,~usdat_sheet(.,1960)),
    map_dfr(0:9,~usdat_sheet(.,1970))
    )

uspops %>%
  mutate(
    age2=as.numeric(gsub("\\+","",age)),
    agebin=.bincode(age2,breaks=c(9,14,19,24,29,34,39,44,49)),
    agebin=factor(agebin,
                      levels=1:8,labels=c("10-14","15-19","20-24",
                                          "25-29","30-34","35-39",
                                          "40-44","45-49")),
    agebin=ifelse(is.na(agebin),"remainder",as.character(agebin)),
    male=as.numeric(male)/1000,
    female=as.numeric(female)/1000,
    num=as.numeric(num)/1000
  ) -> uspops


male <-
  uspops %>%
  group_by(source) %>%
  summarise(total=sum(male))

female <-
  uspops %>%
  group_by(source,agebin) %>%
  summarise(thous = sum(female))

pop_str_data <-
  left_join(female,male) %>%
  mutate(
    thous=ifelse(agebin=="remainder",thous+total,thous),
    year=source
  ) %>% ungroup %>% select(year,agebin,thous)

pop_str_data <- full_join(
  female |> transmute(year=source,agebin,thous),
  male |> transmute(year=source,agebin="remainder",thous=total)
) |>
  group_by(year,agebin) |> summarise(thous=sum(thous))


pop_str_add <- tibble(
  year = rep(1980:1990,e=9),
  agebin = rep(c("10-14","15-19","20-24","25-29",
                 "30-34","35-39","40-44","45-49",
                 "remainder"), 11),
  thous = c(8923,10377,10680,9896,8974,7159,5988,5677,159581,
            8953,10080,10790,10132,9481,7310,6136,5643,161112,
            8877,9779,10781,10396,9482,7918,6354,5656,162753,
            8747,9471,10729,10607,9672,8201,6699,5754,164404,
            8544,9231,10642,10753,9900,8584,6942,5872,165997,
            8339,9106,10482,10869,10172,8967,7167,5968,167666,
            8078,9126,10183,10982,10407,9467,7316,6110,169436,
            8035,9047,9877,10971,10674,9466,7929,6325,171103,
            8102,8923,9576,10924,10895,9660,8210,6668,172847,
            8260,8721,9335,10837,11059,9890,8589,6920,174648,
            8447,8525,9223,10691,11175,10167,8987,7150,176648)
)

pop_str_data <- bind_rows(pop_str_data, pop_str_add)


#https://data.cdc.gov/NCHS/NCHS-Birth-Rates-for-Females-by-Age-Group-United-S/yt7u-eiyg/data

birthdata <-
read_csv("C:/Users/jking34/Downloads/NCHS_-_Birth_Rates_for_Females_by_Age_Group__United_States.csv") %>%
  mutate(
    agebin=gsub(" Years","",`Age Group`),
    birthrate=`Birth Rate`,
    year=Year
  ) %>% select(year,agebin,birthrate)

birthrate_add <- tibble(
  year = rep(1980:1990,e=9),
  agebin = rep(c("10-14","15-19","20-24","25-29",
                 "30-34","35-39","40-44","45-49",
                 "remainder"), 11),
  birthrate = c(1.1,53.0,115.1,112.9,61.9,19.8,3.9,.2,0,
                1.1,52.7,111.8,112.0,61.4,20.0,3.8,.2,0,
                1.1,52.9,111.3,111.0,64.2,21.1,3.9,.2,0,
                1.1,51.7,108.3,108.7,64.6,22.1,3.8,.2,0,
                1.2,50.9,107.3,108.3,66.5,22.8,3.9,.2,0,
                1.2,51.3,108.9,110.5,68.5,23.9,4.0,.2,0,
                1.3,50.6,108.2,109.2,69.3,24.3,4.1,.2,0,
                1.3,51.1,108.9,110.8,71.3,26.2,4.4,.2,0,
                1.3,53.6,111.5,113.4,72.7,27.9,4.8,.2,0,
                1.4,58.1,115.4,116.6,76.2,29.7,5.2,.2,0,
                1.5,60.7,120.6,121.8,79.6,31.0,5.4,.2,0)
)

birthdata <- bind_rows(birthdata, birthrate_add)





ratedata <-
  left_join(pop_str_data, birthdata) %>%
  mutate(
    birthrate=ifelse(agebin=="remainder",0,birthrate)
  )

left_join(ratedata,
          ratedata %>% group_by(year) %>%
            summarise(
              totalpop=sum(thous)
            )
  ) %>%
  mutate(
    pop_str=thous/totalpop
  ) -> ratedata



rates_crude <-
  ratedata %>%
  mutate(rate=birthrate*pop_str) %>%
  group_by(year) %>%
  summarise(rate=sum(rate),
            factor="crude")

ggplot(rates_crude, aes(x=year,y=rate))+geom_path()
ggplot(ratedata, aes(x=year,y=pop_str,col=agebin))+geom_path()

dres.1940 <-
  dgnpop(
    ratedata,
    pop="year",
    factors=c("birthrate","pop_str"),
    id_vars=c("agebin"),
    baseline = 1940
  )


dres.1979 <-
  dgnpop(
    ratedata,
    pop="year",
    factors=c("birthrate","pop_str"),
    id_vars=c("agebin"),
    baseline = 1979
  )

dres.all <-
  dgnpop(
    ratedata,
    pop="year",
    factors=c("birthrate","pop_str"),
    id_vars=c("agebin")
  )

dgr = dg_rates(dres.1940)
dgr79 = dg_rates(dres.1979)
dgrall = dg_rates(dres.all)


bind_rows(
  rates_crude |> mutate(type="crude",year=as.character(year)),
  dgr |> filter(factor=="birthrate") |>
    transmute(year = pop, rate=adj.rate,type=".1940"),
  dgr79 |> filter(factor=="birthrate") |>
    transmute(year = pop, rate=adj.rate,type=".1979"),
  dgrall |> filter(factor=="birthrate") |>
    transmute(year = pop, rate=adj.rate,type=".all")
) |> mutate(year=as.numeric(year)) |>
  arrange(year,type) |>
  #select(-factor) |> pivot_wider(names_from=type,values_from=rate)
  ggplot(aes(x=year,y=rate,col=type,lty=type))+
  geom_line()

dgr |> filter(pop %in% c(1941,1957))


rates_adj <-
  dcomps %>%
  group_by(factor) %>%
  summarise_at(vars(starts_with("pop")),sum) %>%
  gather(year,rate,starts_with("pop")) %>%
  mutate(year=as.numeric(gsub("pop","",year)))

bind_rows(rates_crude,rates_adj) %>%
  ggplot(.,aes(x=year,y=rate,col=factor))+
  geom_path()+
  theme_bw()+
  theme(legend.position="bottom",axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(colour = guide_legend(nrow = 3, byrow = TRUE)) +
  NULL







