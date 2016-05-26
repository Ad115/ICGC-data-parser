*get_gene_sequences.pl* README
==============================

Hola!, si estás leyendo esto es porque quieres utilizar el script **get_gene_sequences.pl**. Realmente no es muy dificil de usar, sólo lo ejecutas, le das la lista de los genes cuando te la pida y listo!

 > Hay un scipt de prueba en la carpeta tests, puedes utilizarlo para ver si hiciste correctamente la instalación y como ejemplo de cómo usar el programa.

 **PERO** el detalle está en las dependencias, para correrlo necesitas SQL, Expat, BioPerl y unos módulos especiales de Ensembl.org, en lo sucesivo te ayudaré a instalarlo todo.

 > Estas instrucciones són para Linux, si tienes Windows, lamentablemente no puedo ayudar :( y tendrás que leer las instrucciones directamente de la página de [la API de Ensembl](http://feb2014.archive.ensembl.org/info/docs/api/api_installation.html).

 (*Nota*: Esos requerimientos los pide la misma base de datos, por mi no habría tanto relajo pero parece que es un mal necesario :S)

 --------------------------------------------------------

Instalar SQL
------------
 A mi me funcionó sólo abrir una terminal y escribir `sudo apt-get install libmysqlclient-dev`, si tienes Ubuntu o parecido debería de funcionar también.

--------------------------------------------------------

Instalar Expat
--------------
 (*Referencia*: [expat](http://expat.sourceforge.net/))
 Esto lo requiere BioPerl (no estoy seguro de si es esencial, pero por si las moscas también lo instalé), para instalarlo, puedes descargar el archivo desde [source-forge](https://sourceforge.net/projects/expat/) o bien con en la terminal:
 ```
  wget http://downloads.sourceforge.net/project/expat/expat/2.1.1/expat-2.1.1.tar.bz2
 ```
 Lo descomprimes con:
 ```
 sudo tar -jxvf expat-2.1.1.tar.bz2
 ```
 Y luego ejecutas lo siguiente en donde estén los archivos descomprimidos:
 ```
sudo ./configure && make && sudo make install
 ```
 Con eso debería bastar.

 --------------------------------------------------------

Instalar BioPerl
----------------
(Referencia: [BioPerl](http://bioperl.org/INSTALL.html))
 - En una terminal ejecuta: `sudo cpan` o, si no funciona: `sudo perl -MCPAN -e shell`, probablemente iniciará un proceso de configuración, de preferencia dale si a todo.

 - Una vez ahí:
 ```
 cpan>  install Module::Build
 cpan>  o conf prefer_installer MB
 cpan>  o conf commit
 cpan>  install CJFIELDS/BioPerl-1.6.924.tar.gz
 ```
 Probablement se tarde un buen rato en ejecutar pruebas, pero dile que si a todo y espera pacientemente, cuando termine dale Ctrl-D para salir de cpan.

Y listo! Ya tienes BioPerl! :D

--------------------------------------------------------

Instalar la API de Ensembl
--------------------------
(Referencia: [Ensembl API Installation](http://feb2014.archive.ensembl.org/info/docs/api/api_installation.html))

Ahora sí, esto es por lo que hicimos toodo lo anterior:

 - Primero, elije una carpeta para instalar la librería, en este tutorial asumo que es ~/ensembl-api, descarga y descomprime los archivos en ella:
 ```
cd ~/ensembl-api
wget ftp://ftp.ensembl.org/pub/ensembl-api.tar.gz
sudo tar -zxvf ensembl-api.tar.gz
 ```

 - Ahora sólo le tienes que decir a Perl dónde se encuentran las librerías que acabas de instalar:
  ```
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-compara/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-variation/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-funcgen/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-io/modules
  PERL5LIB=${PERL5LIB}:${HOME}/ensembl-api/ensembl-tools/modules
  export PERL5LIB
  ```
  Y para que no tengas que ejecutar eso cada vez que abres una nueva terminal, agrega esas líneas al final de el archivo .bashrc de tu home.
