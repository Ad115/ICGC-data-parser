
===================
Mutation recurrence
===================

------------
Introduction
------------

One of the hallmarks of cancer cells is a mutator phenotype, that is, the cell presents an increased genomic mutation rate. This, along with genomic instability and selection pressure from the host and from the cell's microenvironment, gives rise to the usual invasive characteristics of cancerous tissues. Given this, it is understandable the heterogeneity of cancer tumours accross patients and tissues, but also it is notable that such a thing as *cancer hallmarks* and common characteristics (such as gompertzian growth and microenvironment acidification) can exist also across tissues and patients.

The common characteristics may be explained as natural responses to the tissue conditions, e.g. mutator cells adapt more easily to the hostile host tissue conditions than the non-mutant by inactivating apoptosis pathways and/or promoting mitosis; this argument also holds for microenviroment acidification, given the anoxic conditions that ensue when the cancerous cells proliferate uncontrolled, the cells that are able to cope with these conditions (by changing their metabolism) are the ones that are selected for. So, if these are natural cell responses that give rise to similar phenotypes and behaviors, one may ask if this similarity is also in the resulting genotypes, so that cancer cells from different individuals and tissues may end having a similar set of mutations. This would imply the existence of a common genetic pattern for the cancerous cells and would be useful to detect cancerous cells simply by genotyping. 

To find this pattern, we begin by a simplification. We note that, if such a pattern exists, then there could be mutations that occur in a significant portion of the patients (this doesn't have to be the case, but it is useful as a first approximation).  So, our main inquiry becomes: Are there mutations common to a significant part of the cancer samples?

In order to answer this, we note the `International Cancer Genome Consortium <https://dcc.icgc.org/>`_ (ICGC) data releases already contain the necesary information given they specify, for every mutation, the number of patients it was detected in. We developed a set of informatical tools to aid in parsing the ICGC data releases as part of a proyect called the ICGC Data Parser (this is a open-source proyect hosted at `GitHub <https://github.com/Ad115/ICGC-data-parser>`_. For more information about the ICGC Data Parser and the corresponding subproyects, see the proyect's documentation at https://icgc-data-parser.readthedocs.io/). Of particular importance to answer our main question is a set of scripts that aid in parsing the mutation recurrence information were developed, to which we will refer as the `Mutation Recurrence Workflow <https://icgc-data-parser.readthedocs.io/en/master/mutation-recurrence-workflow.html>`_ (we refer to a mutation recurrence event as the appeareance of the same mutation in different patients).

-------
Methods
-------

ICGC Data Parser: The Mutation Recurrence Workflow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

As mentioned above, the scripts in the Mutation Recurrence Workflow where used. These scripts where developed to automate the process of extracting reccurrence of mutations across patients by answering the questions: How many mutations appear in multiple patients? or, specifying further, How many mutations are repeated in n different patients in a given cancer project and a given gene? This data is concentrated in the *mutation recurrence distribution* obtained by the scripts in this workflow. The workflow also contains scripts to use supercomputing cluster capabilities in the analysis and to visualize the results.


The mutation recurrence distribution
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We now explain more formally what we mean with the mutation recurrence distribution.

The discrete distribution of mutation recurrence across patients, is a function :math:`\Phi : \mathbb{N}  \rightarrow \mathbb{N} \cup \left \{ 0 \right \}`. We interpret it as saying that there are :math:`\Phi(n)` mutations that affect (recurr in) :math:`n` patients, for each :math:`n`. 
 
To understand this, begin by asking, for each mutation, ¿How many patients are affected by it? That defines a mapping :math:`m \mapsto p`, from each mutation to the number of patients it affects. Now, for each number of affected donors :math:`p`, we count the number :math:`n` of mutations that map to :math:`p` (i.e. that affect :math:`p` patients) so that :math:`\Phi` is this implied mapping :math:`p \mapsto n` from number of patients affected to the number of mutations that affect that number of patients.


Basic workflow logic
^^^^^^^^^^^^^^^^^^^^

We explode the fact that the `ICGC data <https://icgc-data-parser.readthedocs.io/en/master/icgc-ssm-file.html>`_ already provides, for each mutation, the number of affected patients per project and accross all projects. So, the steps involved are the following:

 1. **Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest**  for each mutation from the raw mutation data (gene "all genes" and/or project "all projects" are allowed). This narrows the scope to only those mutations that are present in the given gene and the given project and from those only get the data that may be useful.

 2. **Counting of the recurrence data**. Specifically, counting how many mutations recurr in ``n`` patients (the workflow question) for each ``n`` in ``1, 2, 3, ...``. In this process the mutation identities are lost, and we are only left with the mutation recurrence distribution.

 3. **Display (plotting) and analysis of the results**.

The following specifies the outputs seen at each step. Each step's input is the input for the next one.

Fetching of the recurrence data (no. of affected donors) for a cancer project and/or gene of interest
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Next we analize a mutation from the ICGC SSM data to get the recurrence data.

Here is the mutation:

 .. code-block:: none

	#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO
	1       100000022       MU39532371      C       T       .       .       CONSEQUENCE=||||||intergenic_region||,RP11-413P11.1|ENSG00000224445|1|RP11-413P11.1-001|ENST00000438829||upstream_gene_variant||;OCCURRENCE=SKCA-BR|1|70|0.01429;affected_donors=1;mutation=C>T;project_count=1;tested_donors=10638

This is mutation `MU39532371` affecting gene `RP11-413P11.1`, we see it is present in only the `SKCA-BR` cancer project, with 1 patient affected in the project and 1 patient affected globally. These (occurrence in gene, project and global ocurrence) is what we where looking for (the recurrence data). This data is now used or discarded according to whether it belongs to the specified gene and cancer project or not.

 .. _counting-results:

Counting of the recurrence data
"""""""""""""""""""""""""""""""

In this step, given the recurrence data for each mutation, we get the mutation recurrence distribution by counting how many mutations affect a given number of patients. As an example, for the next recurrence data:

	*Data obtained with the* ``GetRecurrenceData.pm`` *script in the mutation-recurrence-workflow of the ICGC Data Parser, parsing the last 25 lines of the SSM file from release 22.*

 .. code-block:: none
	
	# Project: All	Gene: All
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

	*Next is the recurrence distribution of the previous data as found with the* ``GetRecurrenceDistribution.pm`` *script from the mutation-recurrence-workflow folder of the ICGC Data Parser.*

 .. code-block:: none
	
	# Project: All  Gene: All       Tested donors: 10638
	MUTATIONS       AFFECTED_DONORS_PER_MUTATION
	21      1
	2       2
	1       3


Display (plotting) and analysis of the results
""""""""""""""""""""""""""""""""""""""""""""""
The :ref:`results` section shows examples of output at this stage.
 
.. _results:
 
Results
^^^^^^^


We used the previous steps to obtain the 

	*The graph was obtained using the* ``recurrence-distribution-plots.nb`` *script from the mutation-recurrence-workflow of the ICGC Data Parser. The data upon which it is based was obtained using the* ``get-recurrence-distributions.all-projects.sge`` *Sun Grid Engine script from the same source, and using the ICGC SSM file from the Data Release 22.*
	
.. figure:: ../images/recurrence-distributions.*
   :name: mutation-recurrence-distribution

   **Figure 1:** *The mutation recurrence distribution log-log plots of 16 oncogenes (along the distribution of all genes).*
   
We can see the distributions follow aproximately lines with a common slope in the log-log plot (even in comparison with the distribution of all genes)this suggest the distributions follow a power law such that :math:`p \mapsto \Phi(p) = A p^{B}`, where A and B are parameters. So, the next step is to fit a power law to the previous distributions. This is shown in the next image:

 .. figure:: ../images/recurrence-best-fits.*
    :name: mutation-recurrence-best-fits
    
The parameter :math:`A` is related to the total number of mutations reported for the given gene and the :math:`B` parameter has an average value of -4.45 and a standard deviaton of 0.8015, with p-values < 0.02 (These are excluding the cases where there are less than 3 data points).

Discussion and conclusions
^^^^^^^^^^^^^^^^^^^^^^^^^^

The fact that the recurrence distributions conform to a power law means that many mutations are present in very few patients, in fact, a huge (43,867,230) number of mutations where found in only one (not necesarily the same) patient (that is, the mutation didn't repeat accross patients) and only 13 where found to be in >10 patients. This means that our main question (Are there mutations common to a significant part of the cancer samples?) should be answered with a no, and thus, if a genetic pattern or template can be found across cancer cells, then it cannot be found by sampling determinated mutations. A surprising answer given the similar phenotypes observed in cancerous samples. Also, the power law distribution may suggest that the mutations follow a critical process, but the mechanics of it are not clear.
