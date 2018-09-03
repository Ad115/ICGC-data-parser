
What is the ICGC-data-parser?
=============================

|Documentation Status|

.. |Documentation Status| image:: https://readthedocs.org/projects/icgc-data-parser/badge/?version=develop
   :target: http://icgc-data-parser.readthedocs.io/en/develop/?badge=develop

A library to ease the parsing of data from the International Cancer Genome 
Consortium data releases, in particular, the simple somatic mutation 
aggregates.


Tutorial
========   

Installation
------------

Install via `PyPI <https://pypi.org/project/ICGC-data-parser/>`__:

::

    pip install ICGC_data_parser

    
Data download
-------------

The base data for the scripts is the ICGC's aggregated of the simple
somatic mutation data. Which can be downloded using

::

    wget https://dcc.icgc.org/api/v1/download?fn=/current/Summary/simple_somatic_mutation.aggregated.vcf.gz

To know more about this file, please read `About the ICGC's simple
somatic mutations
file <https://icgc-data-parser.readthedocs.io/en/master/icgc-ssm-file.html>`__

**WARNING**: The current release of the data contains a malformed
header that causes the library to crash with an ``IndexError``::

    ---------------------------------------------------------------------------
    ValueError                                Traceback (most recent call last)
    ~/.local/lib/python3.6/site-packages/vcf/parser.py in _parse_info(self, info_str)
        389                 try:
    ...
    ...
    ...
    362     def _parse_info(self, info_str):

    ValueError: could not convert string to float: 'PCAWG'
    
This is caused by a bad type specification in the header of the 
VCF file. To solve it, use the lollowing line after creating the 
``SSM_Reader`` object (asuming the reader is in the ``reader`` 
variable)

.. code-block:: python

    # Fix weird bug due to malformed description headers
    reader.infos['studies'] = reader.infos['studies']._replace(type='String')
    
In the future this will be solved in a more elegant way, but for 
now this is what we've got.


Usage
-----

The main class in the project is the ``SSM_Reader``. It allows to read
easily the ICGC mutations file:

.. code:: python


    >>> from ICGC_data_parser import SSM_Reader
        
    # Reads also compressed files!
    >>> reader = SSM_Reader(open('data/simple_somatic_mutations.aggregated.vcf.gz'))
        
    # or...
    >>> reader = SSM_Reader(filename='data/simple_somatic_mutations.aggregated.vcf.gz')
    #                       ^^^^^^^^
    # The filename keyord argument is important, else we get an IndexError
    

The ``SSM_Reader.parse`` method allows to iterate through the records of
the file and access the parts of the record. You can also specify
regular expressions to filter only the lines you want:

.. code:: python


    # Print only the mutations that are in the
    # European Union Breast Cancer project (BRCA-EU).

    >>> for record in reader.parse(filters=['BRCA-EU']):
    ...    print(record.ID, record.CHROM, record.POS)

    MU66865518 1 100141201
    MU65487875 1 100160548
    MU66281118 1 100638179
    MU66254120 1 101352655
    ...

The INFO field is special in the sense that it contains several
subfields, AND those subfields may be list-like entries with more
subfields themselves (in particular the CONSEQUENCE and OCCURRENCE
subfields):

.. code:: python


    # The subfields of the INFO field:
    >>> next(reader).INFO

    {'CONSEQUENCE': [
        '||||||intergenic_region||', 
        'CD1A|ENSG00000158477|+|CD1A-001|ENST00000289429||upstream_gene_variant||'
        ], 
     'OCCURRENCE': [
         'ESAD-UK|1|301|0.00332', 
         'EOPC-DE|1|202|0.00495', 
         'BRCA-EU|1|569|0.00176'
        ],
     'affected_donors': 3, 
     'mutation': 'T>A', 
     'project_count': 3, 
     'studies': None, 
     'tested_donors': 12068}

.. code:: python


    # The description of the CONSEQUENCE subfield
    >>> print(reader.infos['CONSEQUENCE'].desc)

    Mutation consequence predictions annotated by SnpEff (subfields: gene_symbol|gene_affected|gene_strand|transcript_name|transcript_affected|protein_affected|consequence_type|cds_mutation|aa_mutation)

.. code:: python


    # The description of the OCCURRENCE subfield
    >>> print(reader.infos['OCCURRENCE'].desc)

    Mutation occurrence counts broken down by project (subfields: project_code|affected_donors|tested_donors|frequency)

Sometimes we want to also parse the information in those subfields. For
this purpose, the ``SSM_Reader.subfield_parser`` factory method is
useful. This method creates a parser of the specified subfield that
allows easy access to the data:

.. code:: python


    # Create the subfield parser for the CONSEQUENCE subfield
    >>> consequences = reader.subfield_parser('CONSEQUENCE')


    >>> for record in reader.parse():
    ...    # Which genes are affected?
    ...    genes_affected = {c.gene_symbol 
    ...                          for c in consequences(record)
    ...                          if c.gene_affected}
    ...
    ...    print(f'Mutation: {record.ID}')
    ...    print('\t', ", ".join(genes_affected))

    Mutation: MU93246178
         TPM3
    Mutation: MU66962994
         RP11-350G8.9, SHE
    Mutation: MU93246498
         DCST1, ADAM15, RP11-307C12.11
    Mutation: MU66377106
         EFNA3, ADAM15, EFNA4
    ...

The library also contains some helper scripts to manipulate VCF files
(like the ICGC mutations file): - ``vcf_map_assembly.py``: Creates a new
VCF with the positions mapped to another genome assembly. This is useful
because currently the positions reported by ICGC are in the human genome
assembly GRCh37, while the most recent (and the one the rest of the
world uses) is the GRCh38 assembly. - ``vcf_sample.py``: Creates a new
VCF with a fraction of the mutations in the original. The mutations are
randomly sampled but maintain the order they had in the original file.
This is useful when one wants to make small test analysis on the data,
but still wants the results to be representative of all the mutations. -
``vcf_split.py``: Splits the input VCF into several (also valid VCFs),
this is useful in case one wants to split the analyses into processes
that receive one file each.

The specific documentation of the scripts can be obtained by executing:

::

    $ python3 <script name>.py --help

Also, the library is shipped with some Jupyter Notebooks that elaborate
on the examples. Besides, in the notebooks are demonstrated ways
to manage common parsing errors that have to do with malformed input
files.

Meta
----

**Author**: 
`Ad115 <https://agargar.wordpress.com/>`__ -
`Github <https://github.com/Ad115/>`__ – 
a.garcia230395@gmail.com


**Project pages**: 
`Docs <https://icgc-data-parser.readthedocs.io>`__ - `@GitHub <https://github.com/Ad115/ICGC-data-parser/>`__ - `@PyPI <https://pypi.org/project/ICGC-data-parser/>`__

Distributed under the MIT license. See
`LICENSE <https://github.com/Ad115/ICGC_data_parser/blob/master/LICENSE>`__ for
more information.

Contributing
------------

1. Check for open issues or open a fresh issue to start a discussion
   around a feature idea or a bug.
2. Fork `the repository <https://github.com/Ad115/ICGC-data-parser/>`__
   on GitHub to start making your changes to a feature branch, derived
   from the **master** branch.
3. Write a test which shows that the bug was fixed or that the feature
   works as expected.
4. Send a pull request and bug the maintainer until it gets merged and
   published.
