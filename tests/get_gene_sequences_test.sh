# Test script for get_gene_sequences.pl

# Genes to query, just the first 10 genes from https://dcc.icgc.org/search/g
GENES="TTN,TTN-AS1,CSMD1,TP53,LRP1B,CSMD3,PCDH15,RYR2,CNTNAP2,PCDHA1"

get_gene_sequences.pl -g TP53,ENSG00000141736,MDM2,ENSG00000012048,ATM,ENSG00000123374 -l 100