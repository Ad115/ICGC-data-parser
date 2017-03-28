
================================
The mutation recurrence workflow
================================

User documentation for the mutation recurrence workflow. Including description, basic structure logic, description of the implementations and results.

-----------
Description
-----------

In general, the mutation recurrence workflow automates the process of extracting reccurrence of mutations across patients. It answers the question: *How many mutations appear in multiple patients?* or, specifying further, *How many mutations are repeated in* ``n`` *different patients in a given cancer project and a given gene?* This data is concentrated in the mutation recurrence distribution obtained by the scripts in this workflow.

------------------------------------
The mutation recurrence distribution
------------------------------------

We now explain more formally what we mean with the mutation recurrence distribution.

The discrete distribution of mutation recurrence across patients, is a function :math:`\Phi : \mathbb{N}  \rightarrow \mathbb{N} \cup \left \{ 0 \right \}`. We interpret it as saying that there are :math:`\Phi(n)` mutations that affect (recurr in) :math:`n` patients, for each :math:`n`. 
 
To understand this, begin by asking, for each mutation, ¿How many patients are affected by it? That defines a mapping :math:`m \mapsto p`, from each mutation to the number of patients it affects. Now, for each number of affected donors :math:`p`, we count the number :math:`n` of mutations that map to :math:`p` (i.e. that affect :math:`p` patients) so that :math:`\Phi` is this implied mapping :math:`p \mapsto n` from number of patients affected to the number of mutations that affect that number of patients.

---------------------
Basic structure logic
---------------------

This workflow explodes the fact that the `ICGC data <https://icgc-data-parser.readthedocs.io/en/master/icgc-ssm-file.html>`_ already provides, for each mutation, the number of affected patients per project and accross all projects. So, the steps involved are the following:

 1. **Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest**  for each mutation from the raw mutation data (gene "all genes" and/or project "all projects" are allowed). This narrows the scope to only those mutations that are present in the given gene and the given project and from those only get the data that may be useful.

 2. **Counting of the recurrence data**. Specifically, counting how many mutations recurr in ``n`` patients (the workflow question) for each ``n`` in ``1, 2, 3, ...``. In this process the mutation identities are lost, and we are only left with the mutation recurrence distribution.

 3. **Display (plotting) and analysis of the results**. This step involves plotting the resulting distribution and doing an analysis and interpretation of the results.

-------
Results
-------

The following specifies the outputs seen at each step. Each step's input is the input for the next one.

Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest
-----------------------------------------------------------------------------------------------------

Next we analize a mutation from the ICGC SSM data to get the recurrence data.

Here is the mutation:

 .. code-block:: none

	#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO
	1       100000022       MU39532371      C       T       .       .       CONSEQUENCE=||||||intergenic_region||,RP11-413P11.1|ENSG00000224445|1|RP11-413P11.1-001|ENST00000438829||upstream_gene_variant||;OCCURRENCE=SKCA-BR|1|70|0.01429;affected_donors=1;mutation=C>T;project_count=1;tested_donors=10638

This is mutation `MU39532371` affecting gene `RP11-413P11.1`, we see it is present in only the `SKCA-BR` cancer project, with 1 patient affected in the project and 1 patient affected globally. These (occurrence in gene, project and global ocurrence) is what we where looking for (the recurrence data). This data is now used or discarded according to whether it belongs to the specified gene and cancer project or not.

Counting of the recurrence data
-------------------------------

In this step, given the recurrence data for each mutation, we get the mutation recurrence distribution by counting how many mutations affect a given number of patients. As an example, for the next recurrence data:

	*Data obtained with the* ``GetRecurrenceData.pm`` *script in the mutation-recurrence-data folder of this repo, parsing the last 25 lines of the SSM file from release 22.*

 .. code-block:: none
	
	# Project: All  Gene: All
	MUTATION_ID     TOTAL_AFFECTED_DONORS   TOTAL_TESTED_DONORS
	MU15316252      1       10638
	MU40391998      1       10638
	MU67425876      3       10638
	MU40392000      1       10638
	MU46052595      1       10638
	MU15316304      1       10638
	MU35274516      1       10638
	MU15316381      1       10638
	MU43871898      1       10638
	MU43871975      1       10638
	MU67989961      2       10638
	MU42474604      1       10638
	MU43228049      1       10638
	MU49279319      1       10638
	MU33512431      1       10638
	MU47964056      1       10638
	MU49565549      1       10638
	MU59611256      2       10638
	MU42580058      1       10638
	MU63623967      1       10638
	MU30503112      1       10638
	MU44709162      1       10638
	MU44709239      1       10638
	MU44709280      1       10638
	
We find that there are 21 mutations that affect 1 donor, 2 that affect 2 and 1 that affects 3 donors, so the mutation recurrence distribution for this data is :math:`\Phi` such that :math:`\Phi(1)=21,\;\Phi(2)=2,\;\Phi(3)=1` and :math:`\Phi(n)=0` for all :math:`n > 3`.

	*Next is the recurrence distribution of the previous data as found with the* ``GetRecurrenceDistribution.pm`` *script from the mutation-recurrence-data folder of this repo.*

 .. code-block:: none
	
	# Project: All  Gene: All       Tested donors: 10638
	MUTATIONS       AFFECTED_DONORS_PER_MUTATION
	21      1
	2       2
	1       3


Display (plotting) and analysis of the results
----------------------------------------------

The recurrence distribution obtained is then visualized as a plot and one may even compare the data across distributions.

Next is an example, obtained from the recurrence data of 17 main oncogenes across all projects.

	*The graph was obtained using the* ``recurrence-distribution-plots.nb`` *script from the mutation-recurrence-workflow of this repo. The data upon which it is based was obtained using the* ``get-recurrence-distributions.all-projects.sge`` *Sun Grid Engine script from the same folder, and using the ICGC SSM file from the Data Release 22.*
	
.. figure:: images/recurrence-distributions.*
   :name: mutation-recurrence-distribution

   **Figure 1:** *The mutation recurrence distribution log-log plots of 16 oncogenes (along the distribution of all genes).*
   
We can see the distributions follow aproximately lines with a common slope in the log-log plot (even in comparison with the distribution of all genes). This suggests a common mechanism in the procesess leading to the recurrence. This is something that would be hard to deduce with the raw data alone, thus, this shows the usefulness of the data visualization.

-------------------------------
*Appendix I:* Implementation(s)
-------------------------------

*WARNING:* Subject to change.

STEP 1: Fetching of the recurrence data for a cancer project and/or gene of interest
------------------------------------------------------------------------------------

This is implemented in the script ``GetRecurrenceData.pm`` from the ``mutation-recurrence-workflow`` of this repo.

The script retrieves the next fields:

 - MUTATION_ID
 - PROJ_AFFECTED_DONORS
 - PROJ_TESTED_DONORS
 - TOTAL_AFFECTED_DONORS
 - TOTAL_TESTED_DONORS

Usage
......

.. code-block: none

	GetRecurrenceData.pm [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--offline] [--help]

The user provides the gene to search for, the project the input file (ICGC's SSM file) and the desired output file. Optionally, there are flags to work with no internet connection and to ask for help on the command line.

Example output
..............

There already was some sample output in the Results:Counting the recurrence data section from this page (with the PROJ_AFFECTED_DONORS and PROJ_TESTED_DONORS fields chomped out for clarity. We now present another example of recurrence data.

For the command ``GetRecurrenceData.pm -g TP53 -p BRCA-EU -i $ICGC_DATA`` (ICGC_DATA points to the SSM file from the ICGC Data Release 22), the first 7 lines of output are:

.. code-block: none

	# Project: BRCA-EU      Gene: TP53(ENSG00000141510)
	MUTATION_ID     POSITION        MUTATION        PROJ_AFFECTED_DONORS    TOTAL_AFFECTED_DONORS   CONSEQUENCES
	MU65520841      Chrom17(7560698)        T>A     BRCA-EU(1/560)  1/10638(1 projects)     3_prime_UTR_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53),downstream_gene_variant@ENSG00000129244(ATP1B2)
	MU64389958      Chrom17(7560786)        C>G     BRCA-EU(1/560)  1/10638(1 projects)     3_prime_UTR_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53),downstream_gene_variant@ENSG00000129244(ATP1B2)
	MU2068497       Chrom17(7562142)        G>A     BRCA-UK(1/117),BRCA-EU(1/560)   2/10638(2 projects)     intergenic_region,downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53)
	MU65890900      Chrom17(7564637)        C>T     BRCA-EU(1/560)  1/10638(1 projects)     intergenic_region,downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53)
	MU66856006      Chrom17(7564667)        T>C     BRCA-EU(1/560)  1/10638(1 projects)     intergenic_region,downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53)
	MU65622575      Chrom17(7565120)        A>G     BRCA-EU(1/560)  1/10638(1 projects)     downstream_gene_variant@ENSG00000129244(ATP1B2),downstream_gene_variant@ENSG00000141510(TP53),3_prime_UTR_variant@ENSG00000141510(TP53)


**Step 2** Counting of the recurrence data
------------------------------------------

***TODO***

**Step 3** Display (plotting) and analysis of the results
---------------------------------------------------------

***TODO:*** `distribution-plots.nb`

Complete workflow up to counting
--------------------------------

The complete workflow up to the plotting is implemented in serial form in Perl/Bash language by the script ``get_genes_info.pl``
***TODO***
