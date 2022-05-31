library(haven)
library(tidyverse)
library(readxl)
library(magrittr)
library(dtplyr)
library(ggplot2)
library(fixest)
library(DIDmultiplegt)


setwd("C:/Users/mig_s/OneDrive/Documents/Dados IC")
base <- read_dta("Dados Limpos/base")
amc <- as_tibble(read_dta("amcs1991.dta"))

file.list <- list.files("s2id")

numbers_only <- function(x) !grepl("\\D", x)
m<-names(read_excel("AC_2006.xls"))
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
  unite("Cód. IBGE", c("Cód. IBGE", "Código IBGE"), na.rm = TRUE) %>%
  unite("Nº do D.O.U.", c("Nº do D.O.U.","Nº do DOU"), na.rm = TRUE) %>%
  unite("Data do D.O.U.", c("Data do D.O.U.", "Data do DOU"), na.rm = TRUE) %>%
  unite("Desastre", c("Desastre", "Evento"), na.rm = TRUE) %>%
  unite("SE/ECP", c("SE/ECP", 
                    "Situação de Emergência (SE) / Estado de Calamidade Pública (ECP)"), 
        na.rm = TRUE) %>%
  filter(!is.na(Nº)) %>%
  mutate(SE = as.numeric(`SE/ECP`=="SE"),
         ECP = as.numeric(`SE/ECP`=="ECP"),
         `Data do D.O.U.` = to.date(`Data do D.O.U.`),
         ano = as.numeric(format(`Data do D.O.U.`, "%Y")),
         cod2010 = as.numeric(substring(`Cód. IBGE`,1, 
                                        nchar(`Cód. IBGE`)-1)))-> temp
temp%>%
  group_by(ano, cod2010) %>%
  summarise(SE = sum(SE),
            ECP = sum(ECP)) %>%
  ungroup() %>%
  left_join(amc, by=c("cod2010")) -> base1
base1%<>%
  group_by(ano, amc) %>%
  summarise(SE = min(SE),
            ECP = max(ECP))%>%
  ungroup()

dados<-
  left_join(base, base1, by= c("ano", "amc"))%>%
  mutate(across(c(SE, ECP), ~replace(., is.na(.), 0)))

dados%>%
  filter(ano<2011)%>%
  group_by(amc) %>%
  mutate(l1 = lag(ECP, 1),
         l2 = lag(ECP, 2),
         l3 = lag(ECP, 3),
         l4 = lag(ECP, 4),
         f1 = lead(ECP, 1),
         f2 = lead(ECP, 2),
         f3 = lead(ECP, 3),
         f4 = lead(ECP, 4))%>%
  ungroup() %>%
  feols(outmigration ~ f4 +f3+f2+ECP+l1+l2+l3+l4| amc + ano, data = .) %>%
  coefplot()





