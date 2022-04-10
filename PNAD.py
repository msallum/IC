# -*- coding: utf-8 -*-
"""
Created on Mon Apr  4 18:44:11 2022

@author: mig_s
"""

import pandas as pd
import os
import requests
from bs4 import BeautifulSoup

direc = r"C:\Users\mig_s\OneDrive\Documents\Dados IC"
os.chdir(direc)

site = r"https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/"

page = requests.get(site)

soup = BeautifulSoup(page.text, 'html.parser')

tb = soup.table

years = list()
for a in tb.find_all('a'):
    if a['href'][:-1].isnumeric():
        years.append(a['href'])


#%%
for i in years:
    os.mkdir(direc + '\\'+ i[:-1])
    os.chdir(direc + '\\'+ i[:-1])
    p = requests.get(site + i)
    s = BeautifulSoup(p.text, 'html.parser')
    t = s.table
    for a in t.find_all('a'):
        if a['href'][-4] == '.':
            dado = requests.get(site + i + a['href'],  allow_redirects=True)
            open(a['href'], 'wb').write(dado.content)