library(haven)
library(tidyverse)
library(readxl)
library(magrittr)
library(dtplyr)
library(data.table)


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
desastres <- read_excel_allsheets("Dados Limpos/Testes_1.xlsx")


tib <- IBGE %>%
  mutate(match = Nome_Município,
         `Código Município Completo` = as.numeric(`Código Município Completo`)) %>%
  select(`Microrregião Geográfica`,
         `Região Geográfica Imediata`,
         Município,
         Nome_UF,
         match,
         `Mesorregião Geográfica`,
         `Região Geográfica Intermediária`,
         `Código Município Completo`) %>%
  mutate_all(toupper)

transf <- function(df, name, cod = tib){
  df%>%
    mutate(desastre = name,
           Nome_UF = toupper(Nome_UF))%>%
    select(`1991`:`2012`, match, Nome_UF, desastre)%>%
    full_join(cod, by = c("match", "Nome_UF"))%>%
    mutate_if(is.numeric, ~replace(., is.na(.), 0)) 
}

  



desastres %<>%
  map2(., names(.), transf)%>%
  bind_rows() %>%
  pivot_longer(c(`1991`:`2012`), names_to = "ANO") %>% 
  pivot_wider(names_from = desastre, values_from = value)

migr %>%
  group_by(amc_orig, year) %>%
  summarise(outmigration = sum(mig)) %>%
  saveRDS(file = "Dados limpos/outmigration.rds")


