library(haven)
library(tidyverse)
library(readxl)
library(magrittr)


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
desastres <- as_tibble(read_excel_allsheets("Dados Limpos/Testes.xlsx"))

tib <-enframe(desastres$`Estiagem e Seca`$match, name = "id", value = "match")
for (a in names(desastres)){
  desastres[[a]] %>%
    pivot_longer(c(`1991`:`2012`), names_to = a)%>%
    full_join(tib, by = "match") -> tib
}
  
  

migr %>%
  group_by(amc_orig, year) %>%
  summarise(outmigration = sum(mig)) %>%
  saveRDS(file = "Dados limpos/outmigration.rds")


