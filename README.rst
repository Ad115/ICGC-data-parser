
ICGC-data-parser
================

|Documentation Status|

.. |Documentation Status| image:: https://readthedocs.org/projects/icgc-data-parser/badge/?version=develop
   :target: http://icgc-data-parser.readthedocs.io/en/develop/?badge=develop

Easy parsing of data from the International Cancer Genome Consortium
data releases, in particular, the simple somatic mutation aggregates.

Meta
----

**Author**: `Ad115 <https://agargar.wordpress.com/>`__ -
`Github <https://github.com/Ad115/>`__ – a.garcia230395@gmail.com

Distributed under the MIT license. See
`LICENSE <https://github.com/Ad115/PyEnsembl/blob/master/LICENSE>`__ for
more information.

Contributing
------------

1. Check for open issues or open a fresh issue to start a discussion
   around a feature idea or a bug.
2. Fork `the repository <https://github.com/Ad115/ICGC_data_parser/>`__
   on GitHub to start making your changes to a feature branch, derived
   from the **master** branch.
3. Write a test which shows that the bug was fixed or that the feature
   works as expected.
4. Send a pull request and bug the maintainer until it gets merged and
   published.

Installation
============

Install via `PyPI <https://pypi.org/project/ICGC-data-parser/>`__:

::

    pip install ICGC_data_parser

Data download
=============

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


Tutorial
========

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
on the examples below. Besides, in the notebooks are demonstrated ways
to manage common parsing errors that have to do with malformed input
files.

Examples
========

Now we demonstrate more involved examples of what can be done with the
library.

Finding the distribution of mutation consequences
-------------------------------------------------

Whether the mutations affect genes, cause frameshifts, fall in an
intronic region or are silent SNPs, we want to know the relative
abundance of these consequences:

.. code:: python


    from collections import Counter
    from ICGC_data_parser import SSM_Reader


    counter = Counter()

    # Open the mutations file
    mutations = SSM_Reader(filename='data/ssm_sample.vcf')
    consequences = mutations.subfield_parser('CONSEQUENCE')

    for record in mutations:
        consequence_types = [c.consequence_type for c in consequences(record)]
        counter.update(consequence_types)
        

    total = sum(counter.values())
    for consequence_type,n in counter.most_common():
        print(f'{n/total :<10.3%} : {consequence_type}')

::

    60.787%    : intron_variant
    17.344%    : intergenic_region
    8.558%     : downstream_gene_variant
    8.295%     : upstream_gene_variant
    1.657%     : missense_variant
    1.327%     : exon_variant
    0.746%     : synonymous_variant
    0.654%     : 3_prime_UTR_variant
    0.167%     : splice_region_variant
    0.144%     : 5_prime_UTR_variant
    0.103%     : stop_gained
    0.099%     : frameshift_variant
    ...

As we can see, rather unexpectedly, an overwhelming amount of mutations
fall in intronic regions. This is worth of more investigation.


Finding the distribution of mutation recurrence among patients
--------------------------------------------------------------

The ICGC data allows us to know, for each mutation, how many patients
where affected by this mutation (the recurrence of the mutation). Thus,
one can solve the question: Do the mutations in cancer patients follow a
recurring pattern? In which case, the mutation recurrences must be more
or less homogeneously distributed, or: Is it that every patient has
their unique set of mutations? In which case, most mutations would
appear only once.

Let's try to solve this:

.. code:: python

    from collections import Counter
    from ICGC_data_parser import SSM_Reader

    # Open the mutations file
    mutations = SSM_Reader(filename='data/ssm_sample.vcf')

    # Fetch recurrence data per mutation
    recurrence_distribution = Counter(mutation.INFO['affected_donors'] 
                                       for mutation in mutations)

    total = sum(recurrence_distribution.values())
    for mut_recurrence,n in recurrence_distribution.most_common():
        print(f'{n/total :<10.3%} : Mutations recurred in {mut_recurrence} patients.')

::

    92.324%    : Mutations recurred in 1 patients.
    6.058%     : Mutations recurred in 2 patients.
    0.990%     : Mutations recurred in 3 patients.
    0.327%     : Mutations recurred in 4 patients.
    0.132%     : Mutations recurred in 5 patients.
    0.061%     : Mutations recurred in 6 patients.
    0.035%     : Mutations recurred in 7 patients.
    0.026%     : Mutations recurred in 8 patients.
    0.015%     : Mutations recurred in 9 patients.
    0.012%     : Mutations recurred in 10 patients.
    0.010%     : Mutations recurred in 11 patients.
    ...

As we can see, most of the mutations are only present in very few
patients, and taking into account that the file aggregates more than
10,000 patients' worth of data, this tells us that every patient's
mutational footprint is essentially unique.

The Jupyter notebook ``recurrence_distribution.ipynb`` from the library
elaborates on this example and shows how to plot this and fit to a power
law. The presence of a power law means that the mutations present
themselves as randomly as they can: |Mutation recurrence distribution|

.. |Mutation recurrence distribution| image:: recurrence-distribution.png

.. code:: python

    from collections import Counter
    from ICGC_data_parser import SSM_Reader
    
    # Open the mutations file
    mutations = SSM_Reader(filename='data/ssm_sample.vcf')
    
    # Fetch recurrence data per mutation
    recurrence_distribution = Counter(mutation.INFO['affected_donors'] 
                                       for mutation in mutations)
    
    total = sum(recurrence_distribution.values())
    for mut_recurrence,n in recurrence_distribution.most_common():
        print(f'{n/total :<10.3%} : Mutations recurred in {mut_recurrence} patients.')


::

    92.324%    : Mutations recurred in 1 patients.
    6.058%     : Mutations recurred in 2 patients.
    0.990%     : Mutations recurred in 3 patients.
    0.327%     : Mutations recurred in 4 patients.
    0.132%     : Mutations recurred in 5 patients.
    0.061%     : Mutations recurred in 6 patients.
    0.035%     : Mutations recurred in 7 patients.
    0.026%     : Mutations recurred in 8 patients.
    0.015%     : Mutations recurred in 9 patients.
    0.012%     : Mutations recurred in 10 patients.
    0.010%     : Mutations recurred in 11 patients.
    0.003%     : Mutations recurred in 14 patients.
    0.002%     : Mutations recurred in 15 patients.
    0.002%     : Mutations recurred in 12 patients.
    0.001%     : Mutations recurred in 20 patients.
    0.001%     : Mutations recurred in 21 patients.
    0.001%     : Mutations recurred in 13 patients.



Finding the distribution of mutation recurrence among patients
--------------------------------------------------------------

From the above example, we can see that, per nucleotide, the mutations
can be considered essentially random. But, we can try to take a more
coarse grained approach and quantify the mutations by gene so that it
may be that the mutations divide randomly among all genes (in which case
we may find almost all genes with the same number of mutations), or we
may find that some genes have significantly more mutations than the
rest.

This is how we may find out:

.. code:: python


    from collections import Counter
    from ICGC_data_parser import SSM_Reader

    # -- 1. Get the mutations count per gene

    mutations_per_gene = Counter()

    mutations = SSM_Reader(filename='data/ssm_sample.vcf')
    consequences = mutations.subfield_parser('CONSEQUENCE')

    for record in mutations:
        affected_genes = [c.gene_symbol for c in consequences(record) if c.gene_affected]
        mutations_per_gene.update(affected_genes)

        
    # Show partial results
    for gene,mutations in mutations_per_gene.most_common():
        print(f'{gene:<10}: {mutations}')

::

    PCDH15    : 1651
    RBFOX1    : 1041
    CSMD1     : 979
    DLG2      : 941
    SPOCK3    : 929
    DPP10     : 649
    CTNND2    : 632
    ...


.. code:: python


    # -- 2. Now group by number of mutations

    distribution = Counter(mutations_per_gene.values())

::

    X    | NO. OF GENES WITH X MUTATIONS
    ----------------------------------------
    1    | 8600
    2    | 3624
    3    | 1638
    4    | 1403
    6    | 1001
    5    | 877
    8    | 712
    ...


In the script ``mutations_distribution_genes.ipynb`` we can see how we
plot this data. For now, the resulting figure is the following:
|mutations by gene|

.. |mutations by gene| image:: mutations-by-gene.png

But remember that genes have wildly varying lengths: |gene lengths
distribution|

So, the distribution of mutations may be convoluted by the distribution
of gene lengths. In order to smooth out this effect, we want to plot not
the total number of mutations per gene, but the mutation density (the
number of mutations normalized by the gene length).

To do this we need to check gene lengths, and the easiest way to do this
is via the Ensembl REST API, which we may use with the module
``ensembl_rest``. The following shows how to do this:

.. |gene lengths distribution| image:: gene-lengths.png

.. code:: python


    # In order to find out the length of the 
    # genes, we will use the Ensembl REST API.
    import ensembl_rest
    from itertools import islice

    def chunks_of(iterable, size=10):
        """A generator that yields chunks of fixed size from the iterable."""
        iterator = iter(iterable)
        while True:
            next_ = list(islice(iterator, size))
            if next_:
                yield next_
            else:
                break
    # ---


    # -- 3. Normalize mutation counts by gene length

            
    # Instantiate a client for communication with
    # the Ensembl REST API.
    client = ensembl_rest.EnsemblClient()


    normalized_counts = Counter()
    for gene_batch in chunks_of(mutations_per_gene, size=1000):
        # Get information of the genes
        gene_data = client.symbol_post('human',
                                       params={'symbols': gene_batch})
        
        gene_lengths = {gene: data['end'] - data['start'] + 1
                            for gene, data in gene_data.items()}
        
        # Get the normalization
        normalized_counts.update({
            gene: mutations_per_gene[gene] / gene_lengths[gene]
                for gene in gene_data
        })
        


    # Show partial results
    for gene,mutations in normalized_counts.most_common():
         print(f'{gene:<10}: {mutations}')

::

    IGHD7-27  : 0.5454545454545454
    IGKJ1     : 0.2894736842105263
    IGKJ3     : 0.2894736842105263
    IGKJ2     : 0.28205128205128205
    SNORD112  : 0.18181818181818182
    IGHJ3P    : 0.18
    IGHJ5     : 0.16326530612244897
    ...

.. code:: python

    # -- 4. Aggregate by mutation density

    normalized_distribution = Counter(normalized_counts.values())

::

    X         | NO. OF GENES WITH X MUTATION DENSITY
    ----------------------------------------
    0.9346%   | 112
    0.9615%   | 33
    0.9524%   | 26
    0.9434%   | 23
    1.6129%   | 20
    1.8692%   | 20
    0.9804%   | 19
    1.2195%   | 19
    ...

Now we can plot this data. The code to do so is in the notebook
``mutations_distribution_genes.ipynb``. For now, the figure that results
is the following: |Mutation density by gene|

.. |Mutation density by gene| image:: mutations-by-gene-normalized.png

Plotting the mutation density in the chromosomes
------------------------------------------------

The example notebook ``mutation_distribution_chroms.ipynb`` shows how to
plot the mutations distribution in the chromosomes. This is useful when
one wants to compare the variations among different projects. The
resulting figures are as the following one: |Mutations in chromosome|

.. |Mutations in chromosome| image:: chromosome-mutations.png
