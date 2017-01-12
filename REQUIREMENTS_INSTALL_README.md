REQUIREMENTS INSTALLATION README
================================

 Most of the scripts used are written in Perl using the Ensembl Perl API to access easily to the data in their databases. So, those libraries must be installed, and, in turn, they depend on BioPerl, Expat and mySQL. D:!

 What follows are the instructions to install these dependencies. Note this instructions are for Ubuntu Linux only, to use it in another OS you might better read the instructions from the [Ensembl Perl API webpage](http://feb2014.archive.ensembl.org/info/docs/api/api_installation.html).

 --------------------------------------------------------

Installing mySQL
----------------
 Just typing `sudo apt-get install libmysqlclient-dev` in a terminal should be enough.

--------------------------------------------------------

Installing Expat
--------------
 (*Reference*: [expat](http://expat.sourceforge.net/))
 This is required by BioPerl (I'm not shure whether it's essential but I installed anyway), to install it, you can download the source from [source-forge](https://sourceforge.net/projects/expat/) or, if you prefer the console terminal:
 ```
  wget http://downloads.sourceforge.net/project/expat/expat/2.1.1/expat-2.1.1.tar.bz2
 ```
 Then decompress it with:
 ```
 sudo tar -jxvf expat-2.1.1.tar.bz2
 ```
 And this will install it:
 ```
sudo ./configure && make && sudo make install
 ```

 --------------------------------------------------------

Install BioPerl
----------------
(Reference: [BioPerl](http://bioperl.org/INSTALL.html))
 - In the console line type: `sudo cpan`, or: `sudo perl -MCPAN -e shell`, and if it's the first time you excecute that, cpan will enter a configuration process. Preferably say yes to all :P .

 - Once there type:
 ```
 cpan>  install Module::Build
 cpan>  o conf prefer_installer MB
 cpan>  o conf commit
 cpan>  install CJFIELDS/BioPerl-1.6.924.tar.gz
 ```
 It most surely will take a while executing lots of tests. You'll only have to be patient and say yes to everything it prompts. When it's done, type Ctrl-D to exit cpan.

 That's it! You now have BioPerl installed on your machine! :D

--------------------------------------------------------

Install Ensembl Perl API
-------------------------
(Reference: [Ensembl API Installation](http://feb2014.archive.ensembl.org/info/docs/api/api_installation.html))

 Now, what we are all here for:

 - First, choose a folder in which to install the library. In the following, I'll assume that folder is ~/ensembl-api. In that folder you will install and decompress the files:
 ```
cd ~/ensembl-api
wget ftp://ftp.ensembl.org/pub/ensembl-api.tar.gz
sudo tar -zxvf ensembl-api.tar.gz
 ```

 - Now, you need to tell Perl where to find those files, so you must type the following:
  ```
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-compara/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-variation/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-funcgen/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-io/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-tools/modules
  export PERL5LIB
  ```
  And to avoid having to type that every time you statr a terminal window, add those lines at the end of the file .bashrc in your home.
  
  Aaaaanddd... We're done! :D