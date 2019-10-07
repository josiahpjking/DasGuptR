require(tidyverse)
require(readxl)

#https://www.census.gov/data/tables/time-series/demo/popest/pre-1980-national.html
usdat_sheet<-function(i,x){
  df = read_xls(paste0("~/Downloads/uspop/pe-11-",x,"s.xls"),sheet=i+1)
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
    agebin=fct_recode(factor(agebin),
                      "10-14"="1",
                      "15-19"="2",
                      "20-24"="3",
                      "25-29"="4",
                      "30-34"="5",
                      "35-39"="6",
                      "40-44"="7",
                      "45-49"="8"),
    agebin=fct_explicit_na(agebin, na_level = "remainder"),
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



#https://data.cdc.gov/NCHS/NCHS-Birth-Rates-for-Females-by-Age-Group-United-S/yt7u-eiyg/data

birthdata <-
read_csv("~/Downloads/uspop/NCHS_-_Birth_Rates_for_Females_by_Age_Group__United_States.csv") %>%
  mutate(
    agebin=gsub(" years","",`Age Group`),
    birthrate=`Birth Rate`,
    year=Year
  ) %>% select(year,agebin,birthrate)



ratedata <-
  left_join(pop_str_data,birthdata) %>%
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


dcomps<-
  DasGupt_Npop(
    ratedata,
    pop=year,
    birthrate,pop_str,
    id_vars=c(agebin)
  )

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












pop<-read_csv("~/Downloads/uspop/testpop.csv")[,-1]
rate<-read_csv("~/Downloads/uspop/testbrate.csv")[,-1]
pop %>% gather(agebin,thou,2:10) %>%
  left_join(.,
            rate %>% gather(agebin,birthrate,2:10)
  ) -> allrates
left_join(allrates,
          allrates %>% group_by(year) %>%
            summarise(
              totalpop=sum(thou)
            )
) %>%
  mutate(
    pop_str=thou/totalpop
  ) -> allrates

rates_crude <-
  allrates %>%
  mutate(rate=birthrate*pop_str) %>%
  group_by(year) %>%
  summarise(rate=sum(rate),
            factor="crude")

round(rates_crude$rate,digits=1)


ggplot(rates_crude, aes(x=year,y=rate))+geom_path()


# dcomps<-
#   DasGupt_Npop(
#     allrates,
#     pop=year,
#     birthrate,pop_str,
#     id_vars=c(agebin)
#   )
# saveRDS(dcomps,"../decomposition_standardisation/script/uspopdecomped.RDS")
# dcomps<-readRDS("../decomposition_standardisation/script/uspopdecomped.RDS")

dcomps<-readRDS("script/jk_data/uspopdecomped.RDS")

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



require(ggrepel)

#this gets the 1940 standardized and the 1990 standardized rates.
left_join(
  allrates %>% filter(year==1940) %>% mutate(popstr1940=pop_str) %>%
  select(agebin,popstr1940),
  allrates %>% filter(year==1990) %>% mutate(popstr1990=pop_str) %>%
  select(agebin,popstr1990)
) %>%
  left_join(allrates,.) %>%
  mutate(
    rate1940=birthrate*popstr1940,
    rate1990=birthrate*popstr1990,
    ratecrude=birthrate*pop_str
  ) %>%
  group_by(year) %>%
  summarise(
    rate1940=sum(rate1940),
    rate1990=sum(rate1990),
    ratecrude=sum(ratecrude)
  ) %>% gather(factor,rate,2:4) %>%
  bind_rows(.,rates_adj) %>%
  mutate(
    factor=fct_recode(factor(factor),
                      "std 1940"="rate1940",
                      "std 1990"="rate1990",
                      "crude"="ratecrude",
                      "DG age-sex\n adjusted"="birthrate",
                      "birthrate adjusted"="pop_str"
    ),
    label=ifelse(year==max(year),as.character(factor),NA_character_)
  ) %>%
  filter(factor!="birthrate adjusted") %>%
  ggplot(.,aes(x=year,y=rate,col=factor,group=factor))+
  geom_path()+
  theme_bw()+
  theme(legend.position="bottom",axis.text.x = element_text(angle = 45, hjust = 1)) +
  #guides(colour = guide_legend(nrow = 3, byrow = TRUE)) +
  guides(colour = FALSE) +
  geom_label_repel(aes(label=label),nudge_x=1,na.rm=T)+
  NULL


###
# qqplots adj rates, and factor effects






#little bit of prediction

require(mgcv)
require(itsadug)


train = allrates %>% separate(agebin,c("age1","age2"),"-") %>%
  mutate(
    age=(as.numeric(age2)+as.numeric(age1))/2,
    cohort=year-age,
    agespecbirthrate=birthrate*pop_str
  )

test = train %>% filter(year>1985) %>%
  mutate(
    #year=year+10,
    cohort=year-age
  ) #%>% select(-agespecbirthrate)

train <- train %>% filter(year<=1985)
#train based on age cohort model
m2<-bam(agespecbirthrate~s(cohort,by=factor(age)),data=train)
head(train)

test %>%
  mutate(
    pred=predict(m2,newdata=test,type="link"),
    pred.se=predict(m2,newdata=test,type="link",se=T)$se.fit
  ) %>%
  bind_rows(
    train %>% mutate(pred=predict(m2,newdata=train,type="link")),
    .
  ) %>%
  #train %>% mutate(pred=predict(m2,newdata=train)) %>%
  group_by(year) %>% summarise(rate=sum(agespecbirthrate),
                               pred=sum(pred,na.rm=T), pred.se=sum(pred.se,na.rm=T)) %>%
  ggplot(.,aes(x=year))+
  geom_point(aes(y=rate))+
  geom_point(aes(y=pred),col="red")+
  geom_ribbon(aes(y=pred,ymin=pred-pred.se,ymax=pred+pred.se),alpha=.2)+
  theme_bw()+
  NULL

