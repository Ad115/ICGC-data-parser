.. about:

==========================
About the ICGC-data-parser
==========================

Scripts to automate parsing of data from the International Cancer Genome Consortium data releases, in particular, the simple somatic mutation aggregates.

Developed by  Andrés García (https://agargar.wordpress.com/), Maribel Hernandez and Roberto Romero.

--------------------------
Download and installation
--------------------------

Scripts
~~~~~~~

To download the files in this repo, you can use the green Download button on the `GitHub repository <https://github.com/Ad115/ICGC-data-parser>`_ or enter the following in a Unix terminal

.. code-block:: bash
	
	git clone https://github.com/Ad115/ICGC-data-parser.git


Data download
~~~~~~~~~~~~~

The base data for the scripts is the ICGC's aggregated of the simple somatic mutation data. Which can be downloded using

.. code-block:: bash
	
	wget https://dcc.icgc.org/api/v1/download?fn=/current/Summary/simple_somatic_mutation.aggregated.vcf.gz

To know more about this file, please read :doc:`About the ICGC's simple somatic mutations file <icgc-ssm-file>`


Requisites installation
~~~~~~~~~~~~~~~~~~~~~~~

The main scripts are written in Perl and use the Ensembl Perl API for which detailed instructions of installation are in :doc:`How to install the Ensembl Perl API <installation>`.

Plotting and analysis of results are implemented in Wolfram Mathematica notebooks. *TODO:* Change it to a free platform or add alternate scripts in a free platform.

The scripts in the *SunGridEngine-scripts* folder, as it's name indicates, are designed for running in a Sun Grid Engine cluster and thus will break if tried to run on a typical personal computer. Despite this, they are mostly a convenience and their functionality is still in other alternative scriptsfor each pipeline. See the :ref:`Usage` section for more details.

.. _Usage:

------
Usage
------

The scripts are divided in workflows or pipelines. The pipelines currently implemented are the following:

 -  **Mutation recurrence count**: Automates the process of extracting reccurrence of mutations across patients, it answers the question: *How many mutations appear in multiple patients?* or, specifying further, *how many mutations are repeated in `n` different patients in a given cancer project and a given gene?* This workflow is further documented in :doc:`The mutation recurrence workflow <mutation-recurrence-workflow>`.

 -  **Locating mutations in the genome**: Automates the process of searching where does each mutation fall relative to a gene. In particular, it answers the questions: *How many (and which) mutations fall in INTRONIC, EXONIC or INTERGENIC regions?* and *if a mutation falls in an exon, which base of the codon does it affects?* *TODO:* This pipeline is further documented in :ref:`The mutation locating workflow <mutation-locating-workflow>`.

 - **Distribution of the mutations in the genes**: Automation of the extraction of the distribution of mutations in the genes. It answers the question of *how many genes contain `x` number of mutations in a given gene or project?* *TODO:* This is further documented in :doc:`The mutations distribution workflow <reports/mutation-distribution-report>`.

 -  **Simple Ensembl Perl API convenience scripts**: These are small convenience scripts constructed with the intention to test the Ensembl Perl API but serve as integral programs on their own. These are found in the `ensembl_API folder <https://github.com/Ad115/ICGC-data-parser/tree/develop/ensembl_API>`_ . *TODO:* These are further documented in :ref:`The Ensembl Perl API scripts <ensembl-scripts>`.

---------
 *TO DO*
---------

  - [ ] Cleanup every workflow and document it.
