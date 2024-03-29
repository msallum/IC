library(haven)
library(tidyverse)
library(readxl)
library(magrittr)
library(dtplyr)
library(ggplot2)
library(fixest)
library(DIDmultiplegt)


setwd("C:/Users/mig_s/OneDrive/Documents/Dados IC")

read_excel_allsheets <- function(filename, tibble = TRUE) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}


migr <- as_tibble(read_dta("mig_orig_dest.dta"))
amc <- as_tibble(read_dta("amcs1991.dta"))
IBGE <- as_tibble(readxl::read_excel("RELATORIO_DTB_BRASIL_MUNICIPIO.xls"))
desastres1 <- read_excel_allsheets("Dados Limpos/Desastres.xlsx")


tib <- IBGE %>%
  mutate(match = Nome_Munic�pio,
         `C�digo Munic�pio Completo` = as.numeric(`C�digo Munic�pio Completo`)) %>%
  select(`Microrregi�o Geogr�fica`,
         `Regi�o Geogr�fica Imediata`,
         Munic�pio,
         Nome_UF,
         match,
         `Mesorregi�o Geogr�fica`,
         `Regi�o Geogr�fica Intermedi�ria`,
         `C�digo Munic�pio Completo`) %>%
  mutate_all(toupper)

transf <- function(df, name, cod = tib){
  df%>%
    mutate(desastre = name,
           Nome_UF = toupper(Nome_UF))%>%
    select(`1991`:`2012`, match, Nome_UF, desastre)%>%
    full_join(cod, by = c("match", "Nome_UF"))%>%
    mutate_if(is.numeric, ~replace(., is.na(.), 0)) 
}

desastres1 %>%
  map2(., names(.), transf)%>%
  bind_rows() %>%
  pivot_longer(c(`1991`:`2012`), names_to = "ANO") %>% 
  pivot_wider(names_from = desastre, values_from = value) %>%
  select(-`NA`)-> desastres

desastres1 %>%
  map2(., names(.), transf)%>%
  bind_rows() %>%
  pivot_longer(c(`1991`:`2012`), names_to = "ANO") %>% 
  pivot_wider(names_from = desastre, values_from = value, values_fn = max) %>%
  select(-`NA`)-> des


migr %>%
  group_by(amc_orig, year) %>%
  summarise(outmigration = sum(mig, na.rm = TRUE)) -> out


des  %>% 
  mutate(across(where(is.double), ~coalesce(.,0))) %>%
  mutate(cod2010 = as.numeric(substring(`C�digo Munic�pio Completo`,1, 
                                        nchar(`C�digo Munic�pio Completo`)-1)),
         ANO = as.numeric(ANO)) %>%
  full_join(amc, by = "cod2010") %>%
  left_join(out, by= c("amc" = "amc_orig", "ANO" = "year")) -> base


base %>%
  group_by(ANO, amc)%>%
  mutate(across(where(is.numeric),max)) %>%
  ungroup()%>%
  select(-c(match,`C�digo Munic�pio Completo`, Munic�pio, cod2010))%>%
  distinct()%>%
  mutate(Total = select(., `Estiagem e Seca`:Geada) %>% rowSums(na.rm = TRUE)) ->base1
  
write_dta(janitor::clean_names(base1), "Dados Limpos/base.dta", )

base1 %>%
  feols(outmigration ~ l(Total, -3:-2) +l(Total, 0:3)| ANO +amc, data = ., panel.id = c('amc', 'ANO'),
        duplicate.method = 'first') %>%
  coefplot()

base1%>%
  group_by(amc) %>%
  mutate(bi = if_else(Total>0, 1, 0),
         l1 = lag(bi, 1),
         l2 = lag(bi, 2),
         l3 = lag(bi, 3),
         l4 = lag(bi, 4),
         f1 = lead(bi, 1),
         f2 = lead(bi, 2),
         f3 = lead(bi, 3),
         f4 = lead(bi, 4)) %>%
  ungroup()-> base

did_multiplegt(base, "outmigration", "amc", "ANO", "bi", placebo = 1)

base%>%
  group_by(amc)%>%
  select(`Estiagem e Seca`:Geada)%>%
  summarise(across(.fn = sum))%>%
  filter()

base %>%
  feols(outmigration ~ f4 +f3+f2+bi+l1+l2+l3+l4| amc + ANO, data = .) %>%
  coefplot()

