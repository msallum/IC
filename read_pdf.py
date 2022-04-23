# -*- coding: utf-8 -*-
"""
Created on Tue Apr 12 15:23:15 2022

@author: mig_s
"""
#"SANTARÉM = JOCA CLAUDINO(PARAÍBA)
#AUGUSTO SEVERO = CAMPO GRANDE(RIO GRANDE DO NORTE)
#PARANÁ ESTIAGEM E SECA TÁ CAGADO
#PG50 MARANHÃO TBM
#BAHIA INUNDAÇÃO
#ESTIAGEM QUARAÍ(RIO GRANDE DO SUL)
import pandas as pd
import pdfplumber
import os
from fuzzywuzzy import fuzz
from fuzzywuzzy import process
from datetime import datetime
#%%
os.chdir(r"C:\Users\mig_s\OneDrive\Documents\Dados IC")

ibge = pd.read_excel(r"RELATORIO_DTB_BRASIL_MUNICIPIO.xls")

ibge["match"]= ibge["Nome_Município"].apply(lambda x: x.upper())
ibge["Código Município Completo"] = ibge["Código Município Completo"].astype(str)
ibge = ibge[["Nome_UF", "Código Município Completo", "match"]]

position = pd.read_excel("Posições.xlsx")
posi_dict =  position.to_dict()

years = ['Município'] + list(range(1991, 2013)) + ['Total']


#%%
data_2 = dict()
for i in range(26):
    data_1 = dict()
    if posi_dict["pdf"][i] == "PA":
        for j in posi_dict.keys():
            if j != "pdf" and j != "Estado" and j != "Diagnóstico":
                try:
                    data_1[j] = pd.read_excel("PA.xlsx", j)
                except ValueError:
                    data_1[j] = pd.DataFrame(columns= years)
    else:
        file = posi_dict["pdf"][i]+".pdf"
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
                        #if posi_dict["pdf"][i] == "PR" and j=="Estiagem e Seca" and k == (39-pg[0]):
                         #   df_sub = pd.read_excel("PR 39.xlsx") #incompleto
                        #elif posi_dict["pdf"][i] == "MA" and j=="Enxurrada" and k == (50-pg[0]):
                         #   print("chegou aqui")
                          #  df_sub = pd.read_excel("MA 50.xlsx") 
                        #else:
                        table= p_tab[k].extract_table()
                        if len(table[0]) > 24:
                            [row.pop() for row in table]
                        df_sub = pd.DataFrame(table[2:], columns= years).replace('', 0)
                        df = df.append(df_sub, True)
                    if posi_dict["pdf"][i] == "PR" and j=="Estiagem e Seca":
                        check= df
                        print(check)
                        sta = df[df["Município"]=="CAPANEMA"].index[0] + 1
                        end = df[df["Município"]=="IBEMA"].index[0]
                        print(sta, end)
                        df.drop(df.index[sta:end], inplace= True)
                        df_sub = pd.read_excel("PR 39.xlsx")
                        df = df.append(df_sub, True)
                    if posi_dict["pdf"][i] == "MA" and j=="Enxurrada":
                        df.drop(df.tail(1).index, inplace= True)
                        df_sub = pd.read_excel("MA 50.xlsx") 
                        df = df.append(df_sub, True)
                elif pd.isnull(posi_dict[j][i]):
                    df = pd.DataFrame(columns= years)
                #temp= ibge[ibge["Nome_UF"] == posi_dict["Estado"][i]]
                #df = pd.to_numeric(df)
                #name = posi_dict["Estado"][i] + "_" + j
                if posi_dict["pdf"][i] == "PB":
                    df.loc[df['Município']== "SANTARÉM", 'Município'] = "JOCA CLAUDINO"
                if posi_dict["pdf"][i] == "RN":
                    df.loc[df['Município']== "AUGUSTO SEVERO", 'Município'] = "CAMPO GRANDE"
                data_1[j] = df.drop(df[df['Município'].str.isnumeric().fillna(True)].index).drop_duplicates()
    data_2[posi_dict["Estado"][i]] = data_1
    
#%%

threshold = 70

for i in data_2.keys():
    if i == "Goiás":
        temp = ibge[(ibge["Nome_UF"] == i) | (ibge["Nome_UF"] == "Distrito Federal")]
    else:
        temp = ibge[ibge["Nome_UF"] == i]
    for j in data_2[i].keys():
        mat1 = []
        mat2 = []
        mat3 = []
        mat4 = []
        mat5 = []
        p = []
        p1 = []
    
        list1 = data_2[i][j]['Município'].tolist()
        list2 = temp['match'].tolist()
        
        
        dt = datetime.now()
        
        print(i+"-"+j)
        print(dt)


  
        # iterating through list1 to extract 
        # it's closest match from list2
        for k in list1:
            mat1.append(process.extract(k, list2, limit=2))
            mat2.append(process.extractOne(k, list2))
        data_2[i][j]['matches'] = mat1
        data_2[i][j]['match'] = mat2
          
        # iterating through the closest matches
        # to filter out the maximum closest match
        for f in data_2[i][j]['matches']:
            for k in f:
                p.append(k[0])
            mat3.append(",".join(p))
            p = []
            
        for k in data_2[i][j]['match']:
            if k[1] >= threshold:
                mat4.append(k[0])
                mat5.append(k[1])
            else:
                mat4.append(0)
                mat5.append(0)
            

            
          
        # storing the resultant matches back to dframe1
        data_2[i][j]['matches'] = mat3
        data_2[i][j]['match'] = mat4
        data_2[i][j]['fit'] = mat5
        data_2[i][j]['Nome_UF'] = i
        #data_2[i][j] = data_2[i][j].merge(temp, how = "left", on=('match', 'Nome_UF'))


#%%
data = dict()
for j in data_2['Acre'].keys():
    des = pd.DataFrame()
    for i in data_2.keys():
        des = des.append(data_2[i][j], True)
    des = des.drop(des[des['match'].str.isnumeric().fillna(True)].index)
    des.drop(des[des['Município'] == 'Município'].index, inplace = True)
    des[list(range(1991, 2013))+["Total"]] = des[list(range(1991, 2013))+["Total"]].apply(pd.to_numeric)
    des["DIF"] = des[list(range(1991, 2013))].sum(axis = 1) -des["Total"]
    data[j] = des.fillna(0).drop_duplicates()
       
#%%

with pd.ExcelWriter(r'Dados limpos/Desastres.xlsx') as writer:
    for i in data.keys():
        data[i].to_excel(writer, sheet_name=i)
