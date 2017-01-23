# Test script for get_gene_sequences.pl

# Genes to query, just the first 10 genes from https://dcc.icgc.org/search/g
GENES="TTN,TTN-AS1,CSMD1,TP53,LRP1B,CSMD3,PCDH15,RYR2,CNTNAP2,PCDHA1"

# Send query to program
echo $GENES | ../get_gene_sequences.pl
