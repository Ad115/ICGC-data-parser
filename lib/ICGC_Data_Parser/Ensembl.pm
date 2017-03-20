
package ICGC_Data_Parser::Ensembl;
	use strict;
	use warnings;
	use Exporter qw'import';

	our @EXPORT_OK = qw(get_gene_query_data);

#============================================================

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.

#============================================================

our $connection; # On-demand connection to Ensembl Database
our %gene_name = ( '' => '' ); # Association gene_stable_id : gene_display_label to avoid querying already seen genes

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
	  
	  # Check if the gene is already in the seen ones
	  if ( my @match = grep { $gene_name{$_} eq $gene_name } keys %gene_name)
	  {
		  return shift @match;
	  }
	  else {
		$connection = ensembldb_connect() unless ($connection);

		# Declare a gene adaptor to get the gene
		my $gene_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Gene' );
		# Declare a gene handler with the given gene
		my $gene = $gene_adaptor->fetch_by_display_label($gene_name);
		unless($gene) { die "ERROR: Gene '$gene_name' not found\n"; }

		# Get the gene's EnsembleStableID
		return $gene->stable_id();
	  }
    }#-------------------------------------------------------

    sub get_display_label
    # Get the display label for the genes in the gene array
    {
    	my $gene_id = shift;
		$connection = ensembldb_connect() unless ($connection);

    	unless ($gene_name{$gene_id})
    	{
            $gene_name{$gene_id} = 'NOLABEL';
    		eval {
    			$gene_name{$gene_id} = $connection
    								-> get_adaptor( 'Human', 'Core', 'Gene' )
    								-> fetch_by_stable_id($gene_id)
    								-> external_name();

    		}; if ($@) { warn $@; }
    	}

        return $gene_name{$gene_id};
    }#-------------------------------------------------------
    
	sub get_gene_query_data
	# Get the relevant data for the given gene
	{
		my $gene = shift; # get gene

		my ($gene_id, $gene_name);
		if ($gene)
		{
			if ($gene =~ /ENSG[0-9]{11}/) # User provided stable ID
			{
				$gene_id = $gene;
				# Get common name
				$gene_name = get_display_label($gene_id);
			}
			elsif (!$gene or lc $gene eq 'all') # User wants to search in all genes
			{
				$gene_id = '';
			}
			else # User provided the display label
			{
				$gene_name = $gene;
				$gene_id = get_gene_id($gene);
			}
		}

		return [$gene_name, $gene_id];
	}#-----------------------------------------------------------

#============================

1; # Return success
