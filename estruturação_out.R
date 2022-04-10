library(haven)
library(tidyverse)


setwd("C:/Users/mig_s/OneDrive/Documentos/GitHub/IC/")

migr <- as_tibble(read_dta("mig_orig_dest.dta"))
amc <- as_tibble(read_dta("amcs1991.dta"))

migr %>%
  group_by(amc_orig, year) %>%
  summarise(outmigration = sum(mig)) %>%
  saveRDS(file = "Dados limpos/outmigration.rds")
