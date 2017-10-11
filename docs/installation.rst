
===================================
How to install the Ensembl Perl API
===================================

 Most of the scripts used are written in Perl using the Ensembl Perl API to access easily to the data in their databases. So, those libraries must be installed, and, in turn, they depend on BioPerl, Expat and mySQL! n(O.O)n

 What follows are the instructions to install these dependencies. Note this instructions are for Ubuntu-based Linux only, to use it in another OS you might better read the instructions from the `Ensembl Perl API webpage <http://feb2014.archive.ensembl.org/info/docs/api/api_installation.html>`_.

--------------------------------------------------------

----------------
Installing mySQL
----------------

Just typing ``sudo apt-get install libmysqlclient-dev`` in a terminal should be enough.

--------------------------------------------------------

----------------
Installing Expat
----------------
(*Reference*: `expat <http://expat.sourceforge.net/>`_)
 
This is required by BioPerl (I'm not shure whether it's essential but I installed anyway), to install it, you can download the source from `source-forge <https://sourceforge.net/projects/expat/>`_ or, if you prefer the console terminal:

.. code-block:: bash

	wget http://downloads.sourceforge.net/project/expat/expat/2.1.1/expat-2.1.1.tar.bz2

Then decompress it with:

.. code-block:: bash

	sudo tar -jxvf expat-2.1.1.tar.bz2

And this will install it:
 
.. code-block:: bash

	sudo ./configure && make && sudo make install

--------------------------------------------------------

------------------
Installing BioPerl
------------------
(Reference: `BioPerl <http://bioperl.org/INSTALL.html>`_)

 - First, install *cpanminus* by entering in a terminal:
 
 .. code-block:: bash
 
    cpan App:cpanminus


 - Then, install *BioPerl* with it:
 
 .. code-block:: bash
 
    cpanm Bio::Perl

It most surely will take a while executing lots of tests. You'll only have to be patient and say yes to everything it prompts.

That's it! You now have BioPerl installed on your machine! :D

--------------------------------------------------------

---------------------------
Installing Ensembl Perl API
---------------------------
(Reference: `Ensembl API Installation <http://feb2014.archive.ensembl.org/info/docs/api/api_installation.html>`_)

 Now, what we are all here for:

 - First, choose a folder in which to install the library. In the following, I'll assume that folder is ``~/ensembl-api``. 
   In that folder you will install and decompress the files:
 
    .. code-block:: bash

        cd ~/ensembl-api
        wget ftp://ftp.ensembl.org/pub/ensembl-api.tar.gz
        sudo tar -zxvf ensembl-api.tar.gz

    
 - Now, you need to tell Perl where to find those files, so type the following:

    .. code-block:: bash

        PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl/modules
        PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-compara/modules
        PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-variation/modules
        PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-funcgen/modules
        PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-io/modules
        PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-tools/modules
        export PERL5LIB

Add those lines at the end of the file ``.bashrc`` in your home to avoid having to type that every time you start a terminal window.

  Aaaaanddd... We're done! :D
