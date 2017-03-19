
package ICGC_Data_Parser::EnsemblPerlAPI;
	use strict;
	use warnings;
	use Exporter qw'import';

	our @EXPORT = qw'$registry, $gene_name';

#============================================================

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.

#============================================================

our $registry = ensembldb_connect();
our %gene_name = ();

#	===========
#	Subroutines
#	===========

    sub ensembldb_connect
    # Initialize a connection to the db
    {
      # Initialize a registry object
      my $registry = 'Bio::EnsEMBL::Registry';

      # Connect to the Ensembl database
      print STDERR "Waiting connection to database... ";
      $registry->load_registry_from_db(
          -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
          -user => 'anonymous'
          );
      print STDERR "Connected to database\n";

      return $registry;
    }#------------------------------------------------------

    sub get_gene_id
    # Query the database for the stable id of the given gene
    {
      my $gene_name = shift;

      # Declare a gene adaptor to get the gene
      my $gene_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Gene' );
      # Declare a gene handler with the given gene
      my $gene = $gene_adaptor->fetch_by_display_label($gene_name);
      unless($gene) { die "ERROR: Gene '$gene_name' not found\n"; }

      # Get the gene's EnsembleStableID
      return $gene->stable_id();
    }#-------------------------------------------------------

    sub get_display_label
    # Get the display label for the genes in the gene array
    {
    	my $gene_id = shift;

    	unless ($gene_name{$gene_id})
    	{
            $gene_name{$gene_id} = 'NOLABEL';
    		eval
    		{
    			$gene_name{$gene_id} = $connection
    								-> get_adaptor( 'Human', 'Core', 'Gene' )
    								-> fetch_by_stable_id($gene_id)
    								-> external_name();

    		}; if ($@) { warn $@; }
    	}

        return $gene_name{$gene_id};
    }#-------------------------------------------------------


#============================

1; # Return success
