# -*- coding: utf-8 -*-
"""
Created on Sun May 22 18:32:41 2022

@author: mig_s
"""

import pandas as pd
import os
import time
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

options = webdriver.ChromeOptions()
options.add_argument('ignore-certificate-errors')
prefs = {"download.default_directory" : r"C:\Users\mig_s\OneDrive\Documents\Dados IC\s2id"}
options.add_experimental_option("prefs", prefs)

driver = webdriver.Chrome(r"C:\Users\mig_s\OneDrive\Área de Trabalho\Drivers\chromedriver.exe",
                          options=options)

driver.get(r"https://s2id.mi.gov.br/paginas/series/")

time.sleep(6)

driver.find_element_by_xpath("/html/body/div[2]/div/form/div[2]/div/div[3]/div[1]/div/label[1]").click()

time.sleep(3)

driver.find_element_by_xpath("/html/body/div[2]/div/form/div[2]/div/div[3]/div[3]/button/span").click()

time.sleep(3)

links = driver.find_elements_by_xpath("//*[@src='/imagens/series/excel.png']")

for link in links:
        driver.execute_script("arguments[0].click();", link)
        time.sleep(1)
