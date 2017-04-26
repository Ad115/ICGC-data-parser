
package ICGC_Data_Parser::Ensembl;
	use strict;
	use warnings;
	use Exporter qw'import';

	our @EXPORT_OK = qw(get_gene_id_data map_GRCh37_to_GRCh38 get_overlapping_genes get_Gene_print_data get_gene_context fetch_slice);
	our %EXPORT_TAGS = (
		'genome' => [qw(get_gene_id_data map_GRCh37_to_GRCh38 get_overlapping_genes get_Gene_print_data get_gene_context fetch_slice)]
	);

#============================================================

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use ICGC_Data_Parser::Tools qw(:debug);

#============================================================

our $connection; # On-demand connection to Ensembl Database
our $slice_adaptor; # Global genomic slice adaptor
our %gene_name; # Association gene_stable_id : gene_display_label to avoid querying already seen genes
our %features; # Associates a feature's (gene, exon, etc...) stable_id with it's data (as a hash containing display_label, start position, end position, etc)

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
	  
		# Check if it's already in the seen ones
		my @match = grep { $features{$_}->{DISPLAY_LABEL} eq $gene } keys %features;
		if( @match ) {
			# It has already been queried for
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
	
			# Get the gene's Ensembl stableID
			my $stable_id = $gene_h->stable_id();
			# Register $stable_id : $display_label on the global $features hash
			$features{$stable_id}->{DISPLAY_LABEL} = {$gene};
			return $stable_id;
		}
    }#-------------------------------------------------------

    sub get_gene_display_label
    # Get the display label for the gene id
    {
    	my $gene_id = shift;
		
		$connection = ensembldb_connect() unless ($connection);

    	unless( defined $features{$gene_id}->{DISPLAY_LABEL} )
    	{
            $features{$gene_id}->{DISPLAY_LABEL} = 'NO-LABEL';
    		eval {
    			$features{$gene_id}->{DISPLAY_LABEL} 
					= $connection
    					-> get_adaptor( 'Human', 'Core', 'Gene' )
    					-> fetch_by_stable_id($gene_id)
    					-> external_name();
    		}; if ($@) { warn $@; }
    	}

        return $features{$gene_id}->{DISPLAY_LABEL};
    }#-------------------------------------------------------
    
	sub get_gene_id_data
	# Get the relevant data for the given gene
	{
		my ($gene, $offline) = @_; # Get options

		# To print in case of error with option 'offline'
		my $offline_error = "Option '--offline' requires gene 'all' or gene's Ensembl stable id"
					."i.e., as an example, instead of gene TP53, gene must be ENSG00000141510\n";
		my ($gene_id, $gene_label);
		
		if (!$gene or lc $gene eq 'all'){
			# Check if user asked for all genes
			$gene_label = $gene_id = '';
		} 
		elsif ($gene =~ /(ENSG[0-9.]*)/){
			# User provided stable ID or a name containing the stable ID
			$gene_id = $1;
			$gene_label = ($offline) ? '' : get_gene_display_label($gene);
		} 
		else {
			# User provided the display label
			die $offline_error if $offline; # Cannot get stable id while offline
			$gene_label = $gene;
			$gene_id = get_gene_stable_id($gene);
		}

		return [$gene_id, $gene_label];
	}#-----------------------------------------------------------
	
	sub fetch_slice
	# Fetches a slice from it's coordinates and length
	{
		my $chromosome = shift;
		my $begin = shift;
		my $length = shift;
		
		my $end = $begin + ($length - 1);
		
		# Fetch slice
		$connection //= ensembldb_connect();
		$slice_adaptor //= $connection -> get_adaptor( 'Human', 'Core', 'Slice' );
		return $slice_adaptor -> fetch_by_region( 'chromosome', $chromosome, $begin, $end );
	}#-----------------------------------------------------------
	
	sub map_GRCh37_to_GRCh38
	# Maps a coordinate in the reference assembly GRCh37 to GRCh38
	{
		my $chromosome = shift;
		my $position = shift;
		my $length = shift;

		my $begin_slice = $position;

		my $slice = fetch_GRCh38_slice_from_GRCh37_region($chromosome, $begin_slice, $length);
		return undef unless ($slice);

		my @return;
		eval { @return = ($slice->start(), $slice->end()); };
		if ($@) { warn $@; }
		return \@return;
	}#-----------------------------------------------------------
	
	sub fetch_GRCh38_slice_from_GRCh37_region
	# Fetches a slice in the GRCh38 assembly from GRCh37 coordinates
	{
		my $chromosome = shift;
		my $begin = shift;
		my $length = shift;

		my $end = $begin + ($length - 1);

		# Fetch slice in the GRCh37 assembly
		my $GRCh37_slice = undef;
		eval { 
			$connection //= ensembldb_connect();
			$slice_adaptor //= $connection -> get_adaptor( 'Human', 'Core', 'Slice' );
			$GRCh37_slice = $slice_adaptor->fetch_by_region( 'chromosome', $chromosome, $begin, $end, '1', 'GRCh37' ); 
			
		}; if ($@) {
				warn $@;
				return undef;
		}

		# Make a projection onto the GRCh38 coordinates
		my $projection = $GRCh37_slice->project('chromosome', 'GRCh38');
		
		my @slices = map { $_ -> to_Slice() } @$projection;
		die "Error while mapping from GRCh37 to GRCh38 assembly!" unless @slices;

		return $slices[0];
	}#-----------------------------------------------------------
	
	sub get_overlapping_genes
	# Returns a list of all genes overlapping the slice
	{
		my $chromosome = shift;
		my $begin = shift;
		my $length = shift;
		
		my $slice = fetch_slice($chromosome, $begin, $length);

		return @{ $slice -> get_all_Genes() };
	}#-----------------------------------------------------------

	sub get_Gene_print_data
	{
		my $gene = shift();
		
		my $stable_id = $gene -> stable_id();
		my $display_label = get_gene_display_label($stable_id);
		
		return "$stable_id($display_label)";
	}#-----------------------------------------------------------
	
	sub get_gene_context
	{
		my $kwargs = shift;

        ## CHECK IF IT IS INTERGENIC
		if ( slice_is_intergenic($kwargs) ) {
			return 'INTERGENIC';
		}
		else {
			# It is overlapping at least one gene
        ##  ## CHECK IF IT IS INTRONIC, EXONIC OR NON-CODING-EXONIC
			my $phase = get_slice_phase($kwargs);
			
			if ( !$phase ){
				return 'INTRONIC';
			} elsif ( $phase == -1 ) {
				return 'NON-CODING-EXONIC';
			} else {
				return "EXONIC:$phase";
			}
		}
	}#-----------------------------------------------------------
	
	sub slice_is_intergenic
	# Checks whether a slice is intergenic or not (is intergenic if it doesn't overlap any gene)
	{
		my ($kwargs) = @_; # Should at least contain a key SLICE
		
		my $slice = $kwargs->{SLICE};
		
		# Get candidate overlapping genes
		my @overlapping
			= @{ $kwargs->{OVERLAPPING_GENES}  
				//= $slice -> get_all_Genes()
			};
		return if @overlapping;
		
		my $overlapping_ids 
			= $kwargs->{OVERLAPPING_GENE_IDs} 
				//= [map { $_ -> stable_id() } @overlapping];
		
		my $slice_interval
			= $kwargs->{SLICE_INTERVAL} 
				//= {
					START => $slice -> start(), 
					END => $slice -> end()
				};
		
		# Check every gene for overlapping
		my ($overlaps, $gene_interval);
		foreach my $i (0..$#overlapping)
		{
			# Get the interval that the gene spans
			my $gene = $overlapping[$i];
			my $gene_interval
				= $features{ $overlapping_ids->[$i] }->{INTERVAL}
					//= { 	START => $gene -> seq_region_start(), 
							END => $gene -> seq_region_end()
						};
			# Does the gene really overlaps the slice?
			$overlaps = overlap($gene_interval, $slice_interval);
			return if $overlaps;
		}
		return 1;
	}#-----------------------------------------------------------

	sub get_slice_phase
	# Gets the starting phase of a slice
	{
		my $kwargs = shift;
		
		my $slice = $kwargs->{SLICE};
		
		my @overlapping_exons
			= @{ $kwargs->{OVERLAPPING_EXONS} 
				//= $slice -> get_all_Exons()
			};
		return unless @overlapping_exons;
				
		my $overlapping_ids 
			= $kwargs->{OVERLAPPING_EXON_IDs} 
				//= [map { $_ -> stable_id() } @overlapping_exons];
		
		my $slice_interval
			= $kwargs->{SLICE_INTERVAL} 
				//= {
					START => $slice -> seq_region_start(), 
					END => $slice -> seq_region_end()
				};
			
		my $mutation_phase = undef;
		foreach my $i (0..$#overlapping_exons)
		{
			# Get the interval that the exon spans
			my $exon = $overlapping_exons[$i];
			my $exon_interval
				= $features{ $overlapping_ids->[$i] }->{INTERVAL}
					//= { 	START => $exon -> seq_region_start(), 
							END => $exon -> seq_region_end()
						};
						
			# Does the exon overlaps the slice?
			if ( overlap($exon_interval, $slice_interval) )
			{
				# Get the phase data
				my $exon_phase 
					= $features{ $overlapping_ids->[$i] }->{PHASE}
						//= $exon -> phase();
				my $exon_start = $exon_interval->{START};
				my $slice_start = $slice_interval->{START};
				# Calculation of the phase
				$mutation_phase = ( $exon_phase + ($slice_start - $exon_start) ) % 3;
				$mutation_phase = -1 if ($exon_phase == -1);

				return $mutation_phase;
			}
		}

	}#-----------------------------------------------------------

	sub overlap
	{
		my ($a, $b) = @_;
		
		# Order intervals
		order($a);
		order($b);
		
		# Do they overlap?
		return ($a->{START} < $b->{START}) 
				? ($b->{START} <= $a->{END}) 
				: ($a->{START} <= $b->{END});
	}#-----------------------------------------------------------
	
	sub order
	{
		($_[0]->{START}, $_[0]->{END}) = ($_[0]->{START} < $_[0]->{END}) 
										? ($_[0]->{START}, $_[0]->{END})
										: ($_[0]->{END}, $_[0]->{START});
	}#-----------------------------------------------------------

#============================

1; # Return success
