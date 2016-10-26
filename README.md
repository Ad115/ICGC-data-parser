# ICGC-data-parser

Scripts to automate parsing of data from the International Cancer Genome Consortium data releases, in particular, the simple somatic mutation aggregates.

To download the files, you can use the green Download button on the [GitHub repository](https://github.com/Ad115/ICGC-data-parser) or enter the following in a Unix terminal:
 ```
 sudo git clone https://github.com/Ad115/ICGC-data-parser.git
 ```

## Usage
 Most of the scripts are written in Perl and use BioPerl and the Ensembl Perl API, detailed instructions to install those are in the [**SEQUENCES_README.md**](https://github.com/Ad115/ICGC-data-parser/blob/develop/SEQUENCES_README.md) file.
 
 Besides, they expect as input the VCF file from ICGC that contains the simple somatic mutation data, which can be downloaded using:
 ```
 wget https://dcc.icgc.org/api/v1/download?fn=/current/Summary/simple_somatic_mutation.aggregated.vcf.gz
 ```
 and it can then be extracted with the `gunzip` command.