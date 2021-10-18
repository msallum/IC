# -*- coding: utf-8 -*-
"""
Created on Sun Oct 10 15:28:51 2021

@author: mig_s
"""

import pandas
import pdfplumber
import os

os.chdir(r"C:\Users\mig_s\OneDrive\Documentos\GitHub\IC")

estados = {
    "AC":"Acre",
    }

file_1 = "ES.pdf"
cs=pdfplumber.open(file_1)

p_tab=cs.pages[36]

table= p_tab.extract_table()
