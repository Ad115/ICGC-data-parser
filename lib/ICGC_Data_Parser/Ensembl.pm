
package ICGC_Data_Parser::Ensembl;
	use strict;
	use warnings;
	use Exporter qw'import';

	our @EXPORT_OK = qw(get_gene_id_data);

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

    sub get_gene_stable_id
    # Query the database for the stable id of the given gene display label
    {
    	my $gene = shift;
	  
		if( my @match = grep { $gene_name{$_} eq $gene } keys %gene_name){
			# Else, check if the gene is already in the seen ones
			return shift @match;
		} else{
			# Else, connect to ensembl and get the stable ID from display label
			$connection = ensembldb_connect() unless ($connection);
	
			# Declare a gene handler with the given gene
			my $gene_h = 
				$connection
					-> get_adaptor( 'Human', 'Core', 'Gene' )
						-> fetch_by_display_label(
								$gene
							);
			unless($gene_h) { die "ERROR: Gene '$gene' not found\n"; }
	
			# Get the gene's EnsembleStableID
			return $gene_h->stable_id();
		}
    }#-------------------------------------------------------

    sub get_gene_display_label
    # Get the display label for the gene id
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
    
	sub get_gene_id_data
	# Get the relevant data for the given gene
	{
		my ($gene, $offline) = @_; # Get options

		# To print in case of error with option 'offline'
		my $offline_error = "Option '--offline' requires gene 'all' or gene's Ensembl stable id"
					."i.e., as an example, instead of gene TP53, gene must be ENSG00000141510\n";
		my ($gene_id, $gene_name);
		
		if (!$gene or lc $gene eq 'all'){
			# Check if user asked for all genes
			$gene_name = $gene_id = '';
		} 
		elsif ($gene =~ /(ENSG[0-9.]*)/){
			# User provided stable ID or a name containing the stable ID
			$gene_id = $1;
			$gene_name = ($offline) ? '' : get_gene_display_label($gene);
		} 
		else {
			# User provided the display label
			die $offline_error if $offline; # Cannot get stable id while offline
			$gene_name = $gene;
			$gene_id = get_gene_stable_id($gene);
		}

		return [$gene_id, $gene_name];
	}#-----------------------------------------------------------

#============================

1; # Return success
