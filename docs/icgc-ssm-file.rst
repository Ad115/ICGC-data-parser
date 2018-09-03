

The ICGC's mutations file
=========================

This is about the infamous ``simple_somatic_mutations.aggregated.vcf`` file 
presented in each ICGC Data Release which contains an aggregated of the 
information of all simple somatic mutations found accross all patients in all 
cancer projects is found.



Download
--------

This file can be downloaded from `the ICGC site data releases site <https://dcc.icgc.org/releases>`_ or using:

.. code-block:: bash 

	wget https://dcc.icgc.org/api/v1/download?fn=/current/Summary/simple_somatic_mutation.aggregated.vcf.gz

To resume an interrupted download use the ``-c`` switch on the previous command.

Then, the file can be extracted with the ``gunzip`` command (or not, the :py:class:`ICGC_data_parser.SSM_Reader`
can read compressed files too ;D).



Structure
---------

The ``simple_somatic_mutations.aggregated.vcf`` file, from now on referred as the SSM file, is a VCF file as specified in `HTS format specifications <https://samtools.github.io/hts-specs/>`_, and in particular, the SSM files are created using the `SnpEff annotation tool <http://snpeff.sourceforge.net/>`_.

In general, the format is similar to a TSV file in which the comments are marked with ``##`` and the headers line with ``#`` and there is one line per simple-somatic-mutation found.


Fields and Header lines
.......................

Next are the 13 heading lines from a SSM file (data release 22)::

	##fileformat=VCFv4.1
	##INFO=<ID=CONSEQUENCE,Number=.,Type=String,Description="Mutation consequence predictions annotated by SnpEff (subfields: gene_symbol|gene_affected|gene_strand|transcript_name|transcript_affected|protein_affected|consequence_type|cds_mutation|aa_mutation)">
	##INFO=<ID=OCCURRENCE,Number=.,Type=String,Description="Mutation occurrence counts broken down by project (subfields: project_code|affected_donors|tested_donors|frequency)">
	##INFO=<ID=affected_donors,Number=1,Type=Integer,Description="Number of donors with the current mutation">
	##INFO=<ID=mutation,Number=1,Type=String,Description="Somatic mutation definition">
	##INFO=<ID=project_count,Number=1,Type=Integer,Description="Number of projects with the current mutation">
	##INFO=<ID=tested_donors,Number=1,Type=Integer,Description="Total number of donors with SSM data available">
	##comment=ICGC open access Simple Somatic Mutations (SSM) data dump in VCF format
	##fileDate=2016-08-16T16:32:17.882-04:00
	##geneModel=ENSEMBL75
	##reference=GRCh37
	##source=ICGC22-12
	#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO

This is what we can see in those lines:
 - *fileformat*: A line specifying the VCF version (4.1).

 - *INFO*: Six lines breaking down each part of the INFO field.

 - *comment*:A general description of the file (*ICGC open access Simple Somatic Mutations (SSM) data dump in VCF format*).

 - *fileDate*: The creation date of the file (August 2016).

 - *geneModel*: A specification of the gene model (ENSEMBL75). This is the nameset used for the annotations in the INFO field. In particular the identifiers and names in the CONSEQUENCE subfield. **WATCH OUT!** Some genes, transcripts and identifiers annotated may have changed for the current release and so may not be found in a direct query. At the moment of writing, the most recent build is Ensembl 87.

 - *reference*: The genome assembly version used for the positions in the reference genome (GRCh37). **WATCH OUT THIS!** The positions may have dramatic changes from one assembly to another. At the moment, the most recent version of the human genome reference is the GRCh38 assembly.

 - *source*: The data source (ICGC Data release 22)

 - **The column headers**: See section :ref:`The column headers <the-column-headers>`.

.. _the-column-headers:

The column headers
..................

The data is split in these fields:
  - **CHROM**: The chromosome the mutation is in.
  - **POS**: The position in the chromosome of the start of the mutation. This is in the reference assembly specified in the initial comments.
  - **ID**: The current mutation's ICGC identifier.
  - **REF**: The sequence found in the reference.
  - **ALT**: The sequence found in the mutated sample, so that the mutation definition is REF>ALT.
  - **QUAL**: The quality of the read. As a general rule, a quality <10 is unreliable.
  - **FILTER**.
  - **INFO**: Additional annotation on the mutation consequences, and occurrence along patients and projects. It is further commented on :ref:`The INFO Field <the-info-field>`

.. _the-info-field:
  
The INFO field
..............

This field annotates predicted consequences, and seen occurrences of the current mutation. The consequences are as seen by the SnpEff package.

There may be multiple consecuences and occurrences of the same mutation, and those need to be clearly specified. Thus the complex form of this field.

In the file, *the parts are separated with a semicolon (* ``;`` *), and each part may have itself subfields, which are separated with pipes (* ``|`` *)*. 
*Alternative parts* (e.g. different consequences for the mutation or occurrences in different cancer projects) *are separated by a comma (* ``,`` *)*.

  - **CONSEQUENCE:** Mutation consequence predictions annotated by SnpEff. Which has itself the next subfields:
 
   1. *gene_symbol,*
   2. *gene_affected,*
   3. *gene_strand,*
   4. *transcript_name,*
   5. *transcript_affected,*
   6. *protein_affected,*
   7. *consequence_type,*
   8. *cds_mutation,*
   9. *aa_mutation*

  - **OCCURRENCE**: Mutation occurrence counts broken down by project. Which has itself the next subfields:
 
    1. *project_code,*
    2. *affected_donors,*
    3. *tested_donors,*
    4. *frequency*

  - **affected_donors**: Total number of donors with the current mutation.

  - **mutation**: Somatic mutation definition, in the form BEFORE>AFTER.

  - **project_count**: Number of projects with the current mutation.

  - **tested_donors**: Total number of donors with SSM data available.


Interpreting a sample mutation
------------------------------

Now we come to try to read an example mutation from the data.

The mutation
............

.. code-block:: none

	#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO
	1       100000022       MU39532371      C       T       .       .       CONSEQUENCE=||||||intergenic_region||,RP11-413P11.1|ENSG00000224445|1|RP11-413P11.1-001|ENST00000438829||upstream_gene_variant||;OCCURRENCE=SKCA-BR|1|70|0.01429;affected_donors=1;mutation=C>T;project_count=1;tested_donors=10638

The interpretation
..................

We can see the data for the mutation **MU39532371**, which is in the chromosome number *1*, at the position *100000022*, and is defined as *C>T*, with no quality or filtering information available. We can also see in the INFO that this mutation has two consequences: one as a mutation ocurring in an intergenic region, and one as a mutation that affects the *ENSG00000224445* gene and it's *ENST00000438829* transcript provoking an *upstream_gene_variant*. Besides, it was found in a sample from the Great Britain's skin cancer ICGC project (*SKCA-BR*) with *1* patient affected out of the *70* in the project and of the *10638* accross all projects.
