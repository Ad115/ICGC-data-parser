
======================================================
On the frequency of simple somatic mutations in cancer
======================================================

--------
Abstract
--------

**Genetic instability is a landmark of cancer, but simple patterns may be hidden behind it's complex evolution laws. This paper presents the results of analysing the distribution of mutations accross genes of the ICGC simple somatic mutations data.**

----------
Background
----------

Cancer is a set of diseases characterized by genetic instability, frequently found as simple-somatic mutations genome wide. The study of this mutations may lead to new insights related to cancer origins, onset and propagation.
The International Cancer Genome Consortium (ICGC) is an international scientific group, founded in 2008, whose goal is to obtain a comprehensive description of genomic, transcriptomic and epigenomic changes accross different tumor types of clinical and societal importance across the globe. For this goal, it has coordinated the analysis of thousands of samples of more than 10,000 patients at genetic, epigenomic and transcriptomic level. Although some of it's data has restricted access, other is publicly available, such as simple somatic mutation data, copy-number mutation data, patients treatment data, etc.
The ICGC releases it's public data as Data Releases at an approximate rate of 2 per semester. The data is organized in Cancer Projects, which separate data from different cancer types and different countries. At the date, the most recent version is Data Release 23 (Dec 2016).
Although the ICGC Data Releases are complete and useful data for many analysis purposes, it may be obtuse for simple information retrieval as is mostly raw data from the samples. The ICGC data parser is a suite of programs whose purpose is to facilitate the retrieval of simple, purposeful data from the ICGC Data Release archives, particularly from the simple somatic mutation (ssm) data.
One of the questions that surges when looking at the ssm data is how many mutations are present in an average gene, and more generally, Are the mutations randomly distributed? and What is the distribution of mutations like accross genes?

--------
Approach
--------

We analyze the simple somatic mutations(ssm) data from the ICGC Data Releases to find the distribution of mutations accross genes. To keep things simple, we analyse only ssm data from the BRCA-EU project, which analyzes ductal breast cancer samples from the European Union.

-------
Methods
-------

We made a Perl script as part of the `ICGC-data-parser <https://github.com/Ad115/ICGC-data-parser>`_ suite to find, in the BRCA-EU project, how many mutations were present in each gene. This is documented as the Mutation Distribution Workflow.

-------
Results
-------

The resulting distribution is in :ref:`Figure 1 <distribution>`.


.. figure:: images/distribution.*
   :name: distribution

   **Figure 1:** *Gene mutation frequency distribution*

We can see that most genes fall in the range of 10-50 mutations in a very sharp peaked distribution leaned towards zero.
To find a probability distribution to interpret the data, several distributions where tested with the aid of the Mathematica software. With the best fit showing a mixture of the Negative Binomial distribution (74%, :math:`r=4`, :math:`p=0.185`) and the Geometric Distribution (25%, :math:`p=0.0053`), fitted with a p value of :math:`7.72 \times 10 ^{-16}`. This is shown in :ref:`Figure 2<best-fit>`

.. figure:: images/best-fit.png
   :name: best-fit
   :alt: Best fit distribution plot
   
   **Figure 2:** *Probability density function of the best fit-distribution along with the normalized data.*

Besides that, we plotted the positions of the most representative genes in breast cancer according to [Yu2016]_. This is shown in :ref:`Figure 3<main-genes>`.

.. figure:: images/main-genes.png
   :name: main-genes
   :alt: Main genes placement in the distribution
   
   **Figure 3:** *Positions in the distribution of the most representative genes in breast cancer*

The plot shows the genes are widely distributed along the tail of the distribution, and so, they themselves may suffice to characterize the distribution.

-----------
Conclusions
-----------

The data shown gives a snapshot of the mutations that may be found in a tumour, and show that the mutation probabilities follow simple laws as shown by the appeareance of the Negative Binomial and the Geometric distribution.

----------
References
----------

.. [Yu2016] Chong Yu, Jin Wang. `A Physical Mechanism and Global Quantification of Breast Cancer <http://dx.doi.org/10.1371/journal.pone.0157422>`_. PLOS ONE 11, e0157422 (2016).