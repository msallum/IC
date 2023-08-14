library(haven)
library(tidyverse)
library(readxl)
library(magrittr)
library(ggplot2)
library(tidylog)

setwd("C:/Users/mig_s/OneDrive/Documents/Dados IC")

pnad_pessoa <- read.csv("PNAD/microdados_compatibilizados_pessoa.csv")

pnad_domicilio <- read.csv("PNAD/microdados_compatibilizados_domicilio.csv")

muni <- as_tibble(read_dta("muni_code95.dta"))

amc <- as_tibble(read_dta("amcs1991.dta"))

pnad_domicilio %>%
  filter(ano>1995) ->vi

mut <- function(id, ano){
  x<-as.character(id)
  case_when(
    ano <= 1999 ~  substring(x, 3, 
                            nchar(x)-3),
    ano > 1999 ~ substring(x, 5, 
                           nchar(x)-3))%>%
    as.numeric()
}

vi %>%
  mutate(
    id = map2(id_domicilio, ano, mut)%>%unlist()) -> teste

teste %>%
  left_join(muni, by = c("id"="pnad_code")) %>%
  left_join(amc, by = c("census_code"= "cod2010")) -> pnad_base 
