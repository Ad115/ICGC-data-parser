# ICGC-data-parser

Scripts to automate parsing of data from the International Cancer Genome Consortium data releases, in particular, the simple somatic mutation aggregates.

To download the files, you can use the green Download button on the [GitHub repository](https://github.com/Ad115/ICGC-data-parser) or enter the following in a Unix terminal:
 ```
 git clone https://github.com/Ad115/ICGC-data-parser.git
 ```

## Usage
 Most of the scripts are written in Perl and use the Ensembl Perl API, detailed instructions of installation are in [How to install the Ensembl Perl API](https://github.com/Ad115/ICGC-data-parser/blob/develop/REQUIREMENTS_INSTALL_README.md).

 Besides, they expect as input the VCF file from ICGC that contains the simple somatic mutation data. To know more about this file and how to retrieve it, please read [About the ICGC's simple somatic mutations file](https://github.com/Ad115/ICGC-data-parser/blob/develop/SSM_DATA_README.md)
