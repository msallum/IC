library(haven)
library(tidyverse)
library(readxl)
library(magrittr)
library(ggplot2)
library(tidylog)
library(fixest)


setwd("C:/Users/mig_s/OneDrive/Documents/Dados IC")
col_types = c("skip", rep("guess", 26), rep("numeric", 2))
data <-readxl::read_excel("Atlas/Atlas.xlsx",
                          col_types = col_types)
am <- as_tibble(read_dta("amcs1991.dta"))
migr <- as_tibble(read_dta("mig_orig_dest.dta"))
ano <- expand_grid(amc = am$amc, ano = 1995:2019)

colMax <- function (colData) {
  apply(colData, MARGIN=c(2), max)
}

lag_dummy<- function(serie, start, final, default = 0){
  m = final-start+1
  map(start:final, ~lag(serie, ., default = default)) %>% 
    unlist() %>% 
    matrix(nrow = m, byrow = TRUE)%>% 
    colMax()
}

lead_dummy<- function(serie, start, final, default = 0){
  m = final-start+1
  map(start:final, ~lead(serie, ., default = default)) %>% 
    unlist() %>% 
    matrix(nrow = m, byrow = TRUE)%>% 
    colMax()
}


amc <- am %>%
  full_join(ano, by = "amc") %>%
  mutate(amc = as.character(amc),
         cod2010 = as.character(cod2010))

migr %>%
  group_by(amc_orig, year) %>%
  summarise(outmigration = sum(mig, na.rm = TRUE))%>%
  ungroup()%>%
  mutate(amc_orig = as.character(amc_orig))-> out

data  %>%
  janitor::clean_names() %>%
  mutate(cod2010 = substring(cod_ibge,1, 
                                        nchar(cod_ibge)-1),
         across(where(is_logical), as.numeric),
         across(danos_materiais_totais_r:prejuizos_publicos,
                ~as.numeric(str_replace_all(str_replace_all(., "\\.", ""),",", "."))))%>%
  mutate(across(where(is.double), ~coalesce(.,0)))->limpo

limpo %>%
  full_join(amc, by = c("cod2010", "ano")) %>%
  distinct()-> agreg 

agreg%>%
  group_by(amc, ano) %>%
  summarise(across(obitos:chuvas_intensas, ~sum(., na.rm = FALSE))) %>%
  ungroup()%>%
  mutate(across(where(is.double), ~coalesce(.,0)))-> temp

temp %>%
  relocate(alagamentos, .after = prejuizos_publicos)%>%
  mutate(desastres = select(., alagamentos:chuvas_intensas) %>% rowSums(na.rm = TRUE)) %>%
  left_join(out, by= c("amc" = "amc_orig", "ano" = "year")) -> base


write_dta(base, "Dados Limpos/Atlas.dta", )  

base%>%
  group_by(ano)%>%
  summarise(across(obitos:chuvas_intensas, ~sum(., na.rm = FALSE)))->a


base%>%
  group_by(amc) %>%
  arrange(ano) %>%
  mutate(`0` = if_else(desastres>0, 1, 0),
         `+1` = lag(`0`, 1, default = 0),
         `+2` = lag(`0`, 2, default = 0),
         `+3` = lag(`0`, 3, default = 0),
         `+4` = lag_dummy(`0`, 4, n(), default = 0),
         `-1` = lead(`0`, 1, default = 0),
         `-2` = lead(`0`, 2, default = 0),
         `-3` = lead(`0`, 3, default = 0),
         `-4` = lead_dummy(`0`, 4, n(), default = 0)) %>%
  ungroup()-> base1


base1 %>%
  feols(outmigration ~ `-4` +`-3`+`-2`+`0`+`+1`+`+2`+`+3`+`+4`| amc + ano, data = .) -> reg
  
reg%>%
  coefplot(main = "Efeito sobre emigração", value.lab = "Valor Estimado e Intervalo de Confiança de 95%")
reg%>%
  coefplot()
