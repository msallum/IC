library(haven)
library(tidyverse)
library(readxl)
library(magrittr)
library(dtplyr)
library(ggplot2)
library(fixest)
library(fastDummies)


setwd("C:/Users/mig_s/OneDrive/Documents/Dados IC")
base <- read_dta("Dados Limpos/base")
amc <- as_tibble(read_dta("amcs1991.dta"))
pop <- read.csv("muni_pop.csv")

file.list <- list.files("s2id")

numbers_only <- function(x) !grepl("\\D", x)
m<-names(read_excel("S2id/AC_2006.xls"))
read_x <- function(x){
  y = read_excel(x)
  if(length(y)<13){
    names(y) <- y %>%
      slice(3)
  }else{
    names(y) <- m
  }
  y %>%
    filter(.,numbers_only(pull(.,1))) %>%
    mutate(across(everything(), as.character))
}

to.date <- function(x){
case_when(
  numbers_only(x) ~ openxlsx::convertToDate(x),
  grepl("-", x, fixed=TRUE) ~ as.Date(x),
  grepl("/", x, fixed=TRUE)& numbers_only(substring(x, 1, 4)) ~ as.Date(x, "%Y/%m/%d"),
  grepl("/", x, fixed=TRUE)& !numbers_only(substring(x, 1, 4)) ~ as.Date(x, "%d/%m/%Y")
)
}
df.list <- lapply(paste0("s2id/", file.list), read_x)

df <- df.list%>%
  bind_rows()

df%>%
  unite("C�d. IBGE", c("C�d. IBGE", "C�digo IBGE"), na.rm = TRUE) %>%
  unite("N� do D.O.U.", c("N� do D.O.U.","N� do DOU"), na.rm = TRUE) %>%
  unite("Data do D.O.U.", c("Data do D.O.U.", "Data do DOU"), na.rm = TRUE) %>%
  unite("Desastre", c("Desastre", "Evento"), na.rm = TRUE) %>%
  unite("SE/ECP", c("SE/ECP", 
                    "Situa��o de Emerg�ncia (SE) / Estado de Calamidade P�blica (ECP)"), 
        na.rm = TRUE) %>%
  filter(!is.na(N�)) %>%
  mutate(SE = as.numeric(`SE/ECP`=="SE"),
         ECP = as.numeric(`SE/ECP`=="ECP"),
         `Data do D.O.U.` = to.date(`Data do D.O.U.`),
         ano = as.numeric(format(`Data do D.O.U.`, "%Y")),
         cod2010 = as.numeric(substring(`C�d. IBGE`,1, 
                                        nchar(`C�d. IBGE`)-1)))-> temp
temp%>%
  group_by(ano, cod2010) %>%
  summarise(SE = sum(SE),
            ECP = sum(ECP)) %>%
  ungroup() %>%
  left_join(amc, by=c("cod2010")) -> base1
base1%<>%
  group_by(ano, amc) %>%
  summarise(SE = max(SE),
            ECP = max(ECP))%>%
  ungroup()

dados<-
  left_join(base, base1, by= c("ano", "amc"))%>%
  mutate(across(c(SE, ECP), ~replace(., is.na(.), 0)))

dados%>%
  select(-c(mesorregiao_geografica, microrregiao_geografica, regiao_geografica_imediata, regiao_geografica_intermediaria)) %>%
  distinct() ->temp

pop%>%
  mutate(cod2010 = as.numeric(substring(id_municipio,1, 
                                        nchar(id_municipio)-1))) %>%
  left_join(amc, by=c("cod2010"))%>%
  group_by(ano, amc)%>%
  summarise(populacao = sum(populacao))%>%
  ungroup()%>%
  distinct()%>%
  right_join(temp, by=c("ano", "amc"))->dados1
  
dados1%>%
  mutate(mig_pct = outmigration/populacao*100)->dados2
  
write_dta(janitor::clean_names(dados2), "Dados Limpos/dados1.dta", )

#fazer outmigration per capita
#PROBLEMA NO COLAPSO POR AMC
#PNAD
#ecp e se discriminados
check<- read_dta("Dados Limpos/dados1.dta")
