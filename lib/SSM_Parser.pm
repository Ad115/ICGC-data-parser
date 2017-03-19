package SSM_Parser;
	use strict;
	use warnings;
	use Exporter qw'import';

	our @EXPORT_OK = qw'get_vcf_line get_vcf_fields parse_fields parse_mutation get_simple_gene_query_data get_project_query_data';
	our %EXPORT_TAGS = (
		'parse' => [qw'get_vcf_line get_vcf_fields parse_fields parse_mutation get_simple_gene_query_data get_project_query_data']
	);

#============================================================

use lib '.';
	use General qw 'tweet';

#============================================================

#	===========
#	Subroutines
#	===========


	sub get_vcf_line
	# Get a line from a VCF file
	{
		my $vcffile = shift;

		# Skip comments
		my $line;
		do	{ $line = <$vcffile>; }
		while($line and $line =~ /^##.*/);

		# Check whether you are in the headers line
		if ($line and $line =~ /^#(.*)/) { $line = $1; }

		return $line;
	}#-----------------------------------------------------------

	sub get_vcf_fields
	# Get a line from a VCF file splitted in fields
	{
		my $vcffile = shift;

		return split( /\t/, get_vcf_line($vcffile) );
	}#-----------------------------------------------------------

	sub parse_fields
	# returns a dictionary with the positions of the fields
	{
		my $inputfile = shift; # The input file
		my @fields = @_;	# The fields to search
			# If fields weren't specified, get all available ones
			@fields = get_vcf_fields($inputfile) unless (@_);

		# Get the column position of the searched fields
		my %fields = map {
						$_ => get_col_number($_, \@fields)
					} @fields;

		return %fields;
	}#-----------------------------------------------------------

	sub get_col_number
	# Get the numeric position of the column whose name is given
	{
		my $col_name = shift;
		my @fields = @{shift()};

		# Get the column numbers
		foreach my $i (0..$#fields)
		{
			return $i if ($col_name eq $fields[$i]);
		}

		die "Column '$col_name' not found!\n!";
	}#-----------------------------------------------------------

	sub get_simple_gene_query_data
	# Get the relevant data for the given gene (given stable id)
	{
		my ($gene_id) = @_; # display label and stable id

		if ( lc $gene_id eq 'all') { # User wants to search in all genes
			$gene_id = '';
		}

		my $gene_str = ($gene_id) ? "$gene_id" : "All";
		my $gene_re = ($gene_id) ? qr/$gene_id/ : qr/.*/;

		return [$gene_str, $gene_re];
	}#-----------------------------------------------------------

	sub get_project_query_data
	# Get the relevant data for the given project
	{
		my $project = shift;

		if ( lc $project eq 'all') { # User wants to search in all genes
			$project = '';
		}
		# Stringify project
		my $project_str = ($project) ? $project : "All";
		# Compile a REGEX with the project name
		my $project_re = ($project) ? qr/$project/ : qr/.*/;

		return [$project_str, $project_re];
	}#-----------------------------------------------------------

	sub split_in_fields
	# Get a hash with the line decomposed in fields
	{
		my %fields = %{ shift() };
		my @line = split( /\t/, shift() );

		my %line = map { $_ => $line[$fields{$_}] } keys %fields;

		return \%line;
	}#-----------------------------------------------------------

	sub get_consequence_data
	# Get the consequence data as a hash array from the mutation line
	{
	    my ($line, $gene_re) = @_;

	    # Get the CONSEQUENCE field
	    $line =~ /CONSEQUENCE=(.*?);/;

	    # Split multiple consequences
		my @consequences
			= map {# Assemble the consequence hashes
	                my @consequence=split /\|/, $_;
	                {   'gene_symbol'	=>	$consequence[0],
						'gene_affected' =>  $consequence[1],
						'gene_strand' =>  $consequence[2],
						'transcript_name' =>  $consequence[3],
						'transcript_affected' =>  $consequence[4],
						'protein_affected' =>  $consequence[5],
	                    'consequence_type'  => $consequence[6],
						'cds_mutation' =>  $consequence[7],
						'aa_mutation' =>  $consequence[8]
	                };
				} grep {
					 $_ =~ ($gene_re) ? $gene_re : qr/.*/ # Filter by gene
				} split( /,/ , $1); # Split by commas

		return \@consequences;
	}#-----------------------------------------------------------

	sub get_occurrence_data
	# Get the occurrence data as a hash array from the mutation line
	{
		my ($line, $project_re) = @_;

		# Get the OCCURRENCE field
		$line =~ /OCCURRENCE=(.*?);/;

		# Split multiple occurrences
	    my @occurrences
			= map {
	                my @occurrence = split /\|/, $_;
	                {   'project_code'	=>	$occurrence[0],
						'affected_donors' =>  $occurrence[1],
						'tested_donors' =>  $occurrence[2],
						'frequency' =>  $occurrence[3]
	                };
				} grep {
					 $_ =~ ($project_re) ? $project_re : qr/.*/ # Filter by project
				} split( /,/ , $1); # Split by commas

		return \@occurrences;
	}#-----------------------------------------------------------

	sub parse_INFO
	# Get a hash with the data in the INFO field
	{
		my ($line, $fields, $gene_re, $project_re) = @_;

		$line =~ /affected_donors=(.*?);.*mutation=(.*?);.*project_count=(.*?);.*tested_donors=(.*?)$/;
		my %INFO = (
			'affected_donors'	=>	$1,
			'mutation'		=>	$2,
			'project_count'	=>	$3,
			'tested_donors'	=>	$4
		);
		$INFO{CONSEQUENCE} = get_consequence_data($line, $gene_re);
		$INFO{OCCURRENCE} = get_occurrence_data($line, $project_re);

		return \%INFO;
	}#-----------------------------------------------------------

	sub parse_mutation
	# Get a hash with the mutation data to print
	{
		my ($line, $fields, $gene_re, $project_re) = @_;

		# Split line in fields
		my %line = %{ split_in_fields($fields, $line) };

		my @mutation = %line;

		push( @mutation, %{parse_INFO(@_)} );
		my %mutation = @mutation;
		undef $mutation{INFO};

		return \%mutation;
	}#-----------------------------------------------------------

	#============================================================

1; # Return success
