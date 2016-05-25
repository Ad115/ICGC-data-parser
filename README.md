# ICGC-data-parser
Scripts to automate cancer mutations and related data from the International Cancer Genome Consortium database.

To download the files, you can use the green Download button on the [GitHub repository](https://github.com/Ad115/ICGC-data-parser) or enter the following in a Unix terminal:
 ```
 sudo git clone https://github.com/Ad115/ICGC-data-parser.git
 ```

## Current files
 - **get_gene_sequences.pl** Prompts for a list of gene names and outputs their sequences, downloaded from the Ensembl database.
 >To use it you must have BioPerl and the Ensembl Perl API files installed, detailed instructions are in the [**SEQUENCES_README.md**](https://github.com/Ad115/ICGC-data-parser/blob/develop/SEQUENCES_README.md) file.

 - **TSVfilter.pl** To select specific columns from a TSV file, the format of the data in the ICGC database.

## Next addos
- Script to automate ICGC data release download
- Script to automate associated genomic data download from Ensembl, COSMIC, etc.
