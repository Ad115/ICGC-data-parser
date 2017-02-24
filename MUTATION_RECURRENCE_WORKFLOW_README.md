The mutation recurrence workflow
=================================

Documentation for the mutation recurrence workflow. Including description, basic structure logic, description of the implementations and results.

Description
------------

In general, the mutation recurrence workflow automates the process of extracting reccurrence of mutations across patients, it answers the question: *How many mutations appear in multiple patients?* or, specifying further, *how many mutations are repeated in `n` different patients in a given cancer project and a given gene?*


Basic structure logic
---------------------

This workflow explodes the fact that the [ICGC data](https://github.com/Ad115/ICGC-data-parser/blob/develop/SSM_DATA_README.md) already provides, for each mutation, the number of affected patients per proyect and accross all projects. So, the steps involved are the following:

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

### **Step 1**. 1. Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest

This is implemented in the script **filter_gene_project.pl** which fetches important data from the raw data.

If prompted for help, the script outputs it's embebbed docstring:
```

Usage: filter_gene_project.pl [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--help]

============================
Filter by gene and project
============================

Searches through input file for mutations related to the given gene and the given project.
Prints important data of each in tsv format.

Common genes: TP53(ENSG00000141510), ERBB2(HER2)(ENSG00000141736), MDM2(ENSG00000135679), BRCA1(ENSG00000012048), ATM(ENSG00000149311), CDK2(ENSG00000123374).
Common projects: BRCA-EU, GBM-US.

    -g, --gene
        Gene name, in display form or as stable ID.
        If present, shows only mutations that affect the gene.
        Empty gene or gene 'all' stands for mutations in any gene.

    -p, --project
        ICGC project name.
        If present, shows only mutations found in that project.
        Empty project or project 'all' stands for mutations in any project.

    -i, --in, --vcf
        Name of the input VCF file.
        The file should be in the format of the ICGC simple-somatic-mutation summary
        If not present, input from standard input.

    -o, --out
        Name of the output file.
        If not present output to standard output.

    -h, --help
        Show this text and exit.

Author: Andrés García García @ Oct 2016.

```
***TODO:*** A sample output for this...

This script is also important as the first step of other workflows, to learn more about it, read ***TODO:*** [The filtering script](https://github.com/Ad115/ICGC-data-parser/blob/develop/FILTER_GENE_PROJECT_README.md)

### **Step 3** Counting of the recurrence data.
***TODO***

### **Step 4** Display (plotting) and analysis of the results.
***TODO:*** `distribution-plots.nb`

### Complete workflow up to counting.
The complete workflow up to the plotting is implemented in serial form in Perl/Bash language by the script **get_genes_info.pl**
***TODO***
