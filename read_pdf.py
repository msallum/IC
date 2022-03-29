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

ibge = pd.read_excel(r"RELATORIO_DTB_BRASIL_MUNICIPIO.xls")

ibge["Município"]= ibge["Nome_Município"].apply(lambda x: x.upper())
ibge["Código Município Completo"] = ibge["Código Município Completo"].astype(str)
ibge = ibge[["Nome_UF", "Código Município Completo", "Município"]]

position = pd.read_excel("Posições.xlsx")
posi_dict =  position.to_dict()

years = ['Município'] + list(range(1991, 2013)) + ['Total']

#%%
file_1 = "PA.pdf"
cs=pdfplumber.open(file_1)
data = pd.DataFrame()
p_tab = cs.pages[43:44]
for i in range(len(p_tab)):
    table= p_tab[i].extract_table()
    [row.pop() for row in table]
    df=pd.DataFrame(table[2:], columns= years).replace('', 0)
    data = data.append(df, True)
temp= ibge[ibge["Nome_UF"] == "São Paulo"]
data.merge(temp, on="Município")
#%%
data_2 = dict()
for i in range(26):
    if posi_dict["pdf"][i] == "PA":
        continue
    file = posi_dict["pdf"][i]+".pdf"
    data_1 = dict()
    cs=pdfplumber.open(file)
    for j in posi_dict.keys():
        if j != "pdf" and j != "Estado" and j != "Diagnóstico":
            if isinstance(posi_dict[j][i], int):
                p_tab = cs.pages[posi_dict[j][i]]
                table = p_tab.extract_table()
                if len(table[0]) > 24:
                    [row.pop() for row in table]
                df = pd.DataFrame(table[2:], columns= years).replace('', 0)
            elif isinstance(posi_dict[j][i], str):
                pg = posi_dict[j][i].split("-")
                pg = list(map(int, pg))
                p_tab = cs.pages[pg[0]:pg[1]]
                df = pd.DataFrame()
                for k in range(len(p_tab)):
                    table= p_tab[k].extract_table()
                    if len(table[0]) > 24:
                        [row.pop() for row in table]
                    df_sub = pd.DataFrame(table[2:], columns= years).replace('', 0)
                    df = df.append(df_sub, True)
            elif pd.isnull(posi_dict[j][i]):
                df = pd.DataFrame(columns= years)
            temp= ibge[ibge["Nome_UF"] == posi_dict["Estado"][i]]
            df = pd.to_numeric(df)
            #name = posi_dict["Estado"][i] + "_" + j
            data_1[j] = df.merge(temp, how = "outer" , on = "Município")
    data_2[posi_dict["Estado"][i]] = data_1
   
#%%
data = dict()
for j in data_2['Acre'].keys():
    des = pd.DataFrame()
    for i in data_2.keys():
        des = des.append(data_2[i][j], True)
    des = des.drop(des[des['Município'].str.isnumeric().fillna(True)].index)
    des[list(range(1991, 2013))] = des[list(range(1991, 2013))].apply(pd.to_numeric)
    data[j] = des.fillna(0)
       
#%%

with pd.ExcelWriter(r'Dados limpos/Dados_limpos.xlsx') as writer:
    for i in data.keys():
        data[i].to_excel(writer, sheet_name=i)
