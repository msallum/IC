library(reticulate)
pd <- import("pandas")
pdfplumber <- import("pdfplumber")
os <- import("os")

os$chdir("C:\\Users\\mig_s\\OneDrive\\Documentos\\GitHub\\IC")

estados = {
  "AC":"Acre",
}

file_1 = "ES.pdf"
cs=pdfplumber$open(file_1)

p_tab=cs$pages[37L]

table= p_tab$extract_table
