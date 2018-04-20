ICGC-data-parser
================

|Documentation Status|

Scripts to automate parsing of data from the International Cancer Genome
Consortium data releases, in particular, the simple somatic mutation
aggregates.



Download and installation
-------------------------

The core module is in PyPi, you can install it using::

    pip install ICGC-data-parser
    
Although the whole example notebooks and helper VCF manipulation scripts are 
in the the `GitHub repository <https://github.com/Ad115/ICGC-data-parser>`__. 
To download the whole thing, enter the repository webpage and click the download 
button or type the following in a Unix terminal::

    git clone https://github.com/Ad115/ICGC-data-parser.git



Data download
~~~~~~~~~~~~~

The main subject of our inquiries is the ICGC's aggregated of the simple
somatic mutation data. Which can be downloded using::

    wget https://dcc.icgc.org/api/v1/download?fn=/current/Summary/simple_somatic_mutation.aggregated.vcf.gz

To know more about this file, please read `About the ICGC's simple
somatic mutations file <https://icgc-data-parser.readthedocs.io/en/master/icgc-ssm-file.html>`__


Usage
-----

The whole package contains example scripts that do the following:

-  **Mutation recurrence count**: Analyzes the data and plots the *Mutation 
   recurrence distribution*. This distribution contains the information regarding:
   *How many mutations appear in more than one patient?* or *How many mutations are 
   repeated among patients?*,  This is further documented in `The mutation recurrence
   workflow <https://icgc-data-parser.readthedocs.io/en/master/mutation-recurrence-workflow.html>`__
   
-  **Mutation density plot**: Plots the mutation density per chromosome along the whole 
   chromosomal length. Allowing to identify visually the randomness of the mutation positions.

-  **Distribution of the mutations in the genes**: Automation of the
   extraction of the distribution of mutations in the genes. It answers
   the question of *how many genes contain ``x`` number of mutations in
   a given gene or project?* ***TODO:*** This is further documented in
   `The mutations distribution workflow 
   <https://github.com/Ad115/ICGC-data-parser/blob/develop/MUTATIONS_DISTRIBUTION_WORKFLOW_README.md>`__


Also, it contains helper scripts to manipulate VCF files, the format of the `ICGC's simple
somatic mutations file <https://icgc-data-parser.readthedocs.io/en/master/icgc-ssm-file.html>`__. 
This scripts are the following:

-   **vcf_map_assembly.py**:  With the help of the `Ensembl REST API <https://rest.ensembl.org/>`__,
    maps the coordinates to the GRCh38 assembly. Assumes the data in the original VCF contains positions 
    in the GRCh37 assembly, as is the case in the data releases until April 2018.
    
-   **vcf_sample.py**:  Take a random sample of the input VCF file. The output is also a valid VCF file.

-   **vcf_split.py**: Split the input VCF file into several valid VCFs.
    

.. |Documentation Status| image:: https://readthedocs.org/projects/icgc-data-parser/badge/?version=develop
   :target: http://icgc-data-parser.readthedocs.io/en/develop/?badge=develop
