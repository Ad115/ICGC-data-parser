The mutation recurrence workflow
=================================

Documentation for the mutation recurrence workflow. Including description, basic structure logic, description of the implementations and results.

Description
------------

In general, the mutation recurrence workflow automates the process of extracting reccurrence of mutations across patients, it answers the question: *How many mutations appear in multiple patients?* or, specifying further, *how many mutations are repeated in `n` different patients in a given cancer project and a given gene?*


Basic structure logic
---------------------

This workflow explodes the fact that the [ICGC data](https://github.com/Ad115/ICGC-data-parser/blob/develop/SSM_DATA_README.md) already provides, for each mutation, the number of affected patients per project and accross all projects. So, the steps involved are the following:

 1. **Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest**  for each mutation from the raw mutation data (gene "all genes" and/or project "all projects" are allowed). This narrows the scope to only those mutations that are present in the given gene and the given project and from those only get the data that may be useful.

 2. **Counting of the recurrence data**. Specifically, counting how many mutations recurr in `n` patients (the workflow question) for each `n` in `1, 2, 3, ...`. In this process the mutation identities are lost, and we are only left of the distribution of mutation recurrence across patients.

 3. **Display (plotting) and analysis of the results**. This step involves plotting the resulting distribution (table) and doing analysis and interpretation of the results.

Results
-------
The following specifies the outputs seen at each step. This output serves as input to the next step.

1. **Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest**

2. **Counting of the recurrence data**. Specifically, counting how many mutations recurr in `n` patients (the workflow question) for each `n` in `1, 2, 3, ...`. In this process the mutation identities are lost, and we are only left of the distribution of mutation recurrence across patients.

3. **Display (plotting) and analysis of the results**. This step involves plotting the resulting distribution (table) and doing analysis and interpretation of the results.


*Appendix I*: Implementation(s)
-----------------

*WARNING:* Subject to change in the near future.

### **Step 1**. Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest

This is implemented in the script **filter_gene_project.pl** which fetches important data from the raw data.

The script retrieves the next fields:
 - MUTATION_ID
 - POSITION
 - MUTATION
 - TOTAL_AFFECTED_DONORS
 - PROJ_AFFECTED_DONORS
 - CONSEQUENCES

#### Usage:
```
filter_gene_project.pl [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--help]
```

The user provides the gene to search for, the project the input file (ICGC's SSM file) and the desired output file.

#### Example output
For the command `filter_gene_project.pl -g TP53 -p BRCA-EU -i $ICGC_DATA` the first 7 lines of output are:
```
# Project: BRCA-EU      Gene: TP53(ENSG00000141510)
MUTATION_ID     POSITION        MUTATION        PROJ_AFFECTED_DONORS    TOTAL_AFFECTED_DONORS   CONSEQUENCES
MU65520841      Chrom17(7560698)        T>A     BRCA-EU(1/560)  1/10638(1 projects)     3_prime_UTR_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53),downstream_gene_variant@ENSG00000129244(ATP1B2)
MU64389958      Chrom17(7560786)        C>G     BRCA-EU(1/560)  1/10638(1 projects)     3_prime_UTR_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53),downstream_gene_variant@ENSG00000129244(ATP1B2)
MU2068497       Chrom17(7562142)        G>A     BRCA-UK(1/117),BRCA-EU(1/560)   2/10638(2 projects)     intergenic_region,downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53)
MU65890900      Chrom17(7564637)        C>T     BRCA-EU(1/560)  1/10638(1 projects)     intergenic_region,downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53)
MU66856006      Chrom17(7564667)        T>C     BRCA-EU(1/560)  1/10638(1 projects)     intergenic_region,downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53)
MU65622575      Chrom17(7565120)        A>G     BRCA-EU(1/560)  1/10638(1 projects)     downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53),3_prime_UTR_variant@ENSG00000141510(TP53)
```

This script is also important as the first step of other workflows, to learn more about it, read ***TODO:*** [The filtering script](https://github.com/Ad115/ICGC-data-parser/blob/develop/FILTER_GENE_PROJECT_README.md)

### **Step 2** Counting of the recurrence data.

***TODO***

### **Step 3** Display (plotting) and analysis of the results.
***TODO:*** `distribution-plots.nb`

### Complete workflow up to counting.
The complete workflow up to the plotting is implemented in serial form in Perl/Bash language by the script **get_genes_info.pl**
***TODO***
