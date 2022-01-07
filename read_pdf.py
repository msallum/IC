# -*- coding: utf-8 -*-
"""
Created on Sun Oct 10 15:28:51 2021

@author: mig_s
"""

import pandas as pd
import pdfplumber
import os
#%%
os.chdir(r"C:\Users\mig_s\OneDrive\Documentos\GitHub\IC")

position = pd.read_excel("Posições.xlsx")

years = ['Município'] + list(range(1991, 2013)) + ['Total']

#%%
file_1 = "MG.pdf"
cs=pdfplumber.open(file_1)
data = pd.DataFrame()
p_tab=cs.pages[36:41]
for i in range(len(p_tab)):
    table= p_tab[i].extract_table()
    [row.pop() for row in table]
    df=pd.DataFrame(table[2:], columns= years).replace('', 0)
    data = data.append(df, True)

