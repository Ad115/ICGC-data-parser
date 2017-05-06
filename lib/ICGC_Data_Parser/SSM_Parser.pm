package ICGC_Data_Parser::SSM_Parser;
	use strict;
	use warnings;
	use Exporter qw'import';
	use Carp qw(croak confess carp cluck); # Module warnings and errors
		#$Carp::Verbose=1; 

	our @EXPORT_OK = qw'get_vcf_line parse_mutation get_gene_data get_project_data 
						get_vcf_headers parse_vcf_headers get_query_re specified
						parse_SSM_file parse_fields';
						
	our %EXPORT_TAGS = (
		'parse' => [qw' get_vcf_line get_vcf_headers parse_mutation get_gene_data
						get_project_data specified get_query_re parse_SSM_file'
					]
	);

#============================================================

use ICGC_Data_Parser::Ensembl qw(get_gene_id_data);
use ICGC_Data_Parser::Tools qw(:general_io :debug);

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
	
	sub get_vcf_headers
	# Get the VCF file headers line
	{
		my $input = shift; # The input file
		
		# Skip comments
		my $line;
		do	{ $line = <$input>; }
		while( $line and $line =~ /^##/ );

		# Check whether you are in the headers line
		if ($line and $line =~ /^#(.*)/) { 
			return $1;
		} else{
			return '';
		}
	}#-----------------------------------------------------------

	sub parse_fields
	# returns a dictionary with the positions of the fields
	{
		my @fields = split( /\t/, shift() );

		# Get the column position of the searched fields
		my %fields = map {
						$_ => get_col_number($_, \@fields)
					} @fields;

		return \%fields;
	}#-----------------------------------------------------------
	
	sub parse_vcf_headers
	# Returns a dictionary with the positions of the header columns of the VCF input
	{
		my $input = shift;
		
		return parse_fields( get_vcf_headers($input) );
	}

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

		croak "Column '$col_name' not found!\n!";
	}#-----------------------------------------------------------

	sub specified
	# Checks if the user asked for a specific project or gene
	{
		my $query = shift;
		return ( $query and !(lc $query eq 'all') );
	}#-----------------------------------------------------------
	
	sub regexp_compile
	{
		my $to_compile = shift;
		
		return (specified $to_compile) ? qr/$to_compile/ : qr/.*/;
	}#-----------------------------------------------------------
	
	sub gene_regexp_compile
	{
		my ($gene, $offline) = @_;
		
		# Get gene stable id
		my $gene_id = get_gene_id_data( $gene, $offline )->[0];
		
		return regexp_compile($gene_id);
	}

	sub get_query_re
	# Get a regexp of the gene and/or project specified
	{
		my ($arg, $offline) = @_;
		
		# Check if labeled strings where asked for
		if ( ref $arg eq 'HASH')
		{
			my %args = %{ $arg }; 
			
			if ( exists $args{gene} )
			{
				# If user asked for the gene's rexexp
				# Compile gene regexp
				my $gene_re = gene_regexp_compile( $args{gene}, $offline );
				
				# Check if user asked for the project regexp too
				if ( exists $args{project} ){
					# Both where specified, return a hash with both
					my $project_re = regexp_compile( $args{project} );
					return {
						gene => $gene_re,
						project => $project_re
					};
					
				} else{
					# Only gene regexp was asked for, return it
					return $gene_re;
				}
			
			} elsif (exists $args{project}){
				# Only wanted project regexp, return it
				return regexp_compile($args{project});
			} else {
				confess "Hash argument must have one of 'project' and 'gene' as keys";
			}
		} else{
			# A simple expression was given to compile. Compile and return it
			return regexp_compile($arg);
		}
			
	}#-----------------------------------------------------------

	sub get_gene_data
	{
		my ($gene, $offline) = @_;

		my ($gene_name, $gene_id);

		# Get gene_id and label
		($gene_id, $gene_name) = @{ get_gene_id_data($gene, $offline) };

		my $gene_str = ($gene_id) ? "$gene_name($gene_id)" : "All";
		my $gene_re = get_query_re($gene_id, $offline);

		return {
			raw	=>	$gene,
			label	=>	$gene_name,
			id	=>	$gene_id,
			str	=>	$gene_str,
			regexp	=>	$gene_re
		};
	}#-----------------------------------------------------------

	sub get_project_data
	{
		my $project = shift;
		
		my $project_str = (specified $project) ? $project : "All";
		my $project_re = get_query_re($project);
		# Get project's data
		return {
			raw	=>	$project,
			str	=>	$project_str,
			regexp	=>	$project_re
		};
	}#-----------------------------------------------------------

	sub parse_line_with_headers
	# Get a hash with the line decomposed in the fields specified in the headers line
	{
		my @line = split( /\t/, shift() );
		my @headers = split( /\t/, shift() );
		
		my %line = map { $_ => shift @line } @headers;
		
		return \%line;
	}#-----------------------------------------------------------

	sub get_consequence_data
	# Get the consequence data as a hash array from the mutation line
	{
	    my %args = %{ shift() };

		# Get the gene regular expression
		my $gene_re = get_query_re({gene => $args{gene}}, $args{offline});

	    # Get the CONSEQUENCE field
	    $args{line} =~ /CONSEQUENCE=(.*?);/;

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
				} grep 
					{ $_ =~ $gene_re } # Filter by gene
						split( /,/ , $1); # Split by commas

		return \@consequences;
	}#-----------------------------------------------------------

	sub get_occurrence_data
	# Get the occurrence data as a hash array from the mutation line
	{
		my %args = %{ shift() };

		# Get the project regular expression
		my $project_re = get_query_re($args{project});

		# Get the OCCURRENCE field
		$args{line} =~ /OCCURRENCE=(.*?);/;

		# Split multiple occurrences
	    my @occurrences
			= map {
	                my @occurrence = split /\|/, $_;
	                {   'project_code'	=>	$occurrence[0],
						'affected_donors' =>  $occurrence[1],
						'tested_donors' =>  $occurrence[2],
						'frequency' =>  $occurrence[3]
	                };
				} grep 
					{ $_ =~ $project_re } # Filter by project
						split( /,/ , $1); # Split by commas

		return \@occurrences;
	}#-----------------------------------------------------------

	sub parse_INFO
	# Get a hash with the data in the INFO field
	{
		my %args = %{ shift() };
		# $line, $gene, $project

		$args{line} =~ /affected_donors=(.*?);.*mutation=(.*?);.*project_count=(.*?);.*tested_donors=(.*?)$/;
		my %INFO = (
			'affected_donors'	=>	$1,
			'mutation'		=>	$2,
			'project_count'	=>	$3,
			'tested_donors'	=>	$4
		);
		$INFO{CONSEQUENCE} = get_consequence_data(\%args);
		$INFO{OCCURRENCE} = get_occurrence_data(\%args);

		return \%INFO;
	}#-----------------------------------------------------------

	sub parse_mutation
	# Get a hash with the mutation data to print
	{
		my %args = %{ shift() };
		# $line, $headers, $gene, $project

		# If the headers line was given, use it
		# Else, use the default headers
		unless ($args{headers})
			{ $args{headers} = 'CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO'; }
			
		# Split line in fields		
		my %line = %{ parse_line_with_headers(
				$args{line}, 
				$args{headers}
			) 
		};

		my %mutation = %line;

		$mutation{INFO} = parse_INFO(\%args);

		return \%mutation;
	}#-----------------------------------------------------------
	
	sub try_action
	{
		my ($context, $action, $otherwise) = @_;
		
		my %actions = %{ $context->{ACTIONS} };
		
		### Check if user defined it's own try_action method
		if (defined $actions{CALLER}) {
			$actions{CALLER}->($context, $action, $otherwise);
			
		} else {
		### Default call
			# Try to execute the action
			if ($actions{$action}){
				eval { $actions{$action}->($context) }; 
			} else {
				$otherwise->($context) if $otherwise;
			}
			
			# If there was something wrong, say it and execute the $otherwise callback
			if ($@) { 
				carp $@;
				$otherwise->($context) if $otherwise;
			}
		}
	}#-----------------------------------------------------------
	
	use Getopt::Long qw(GetOptionsFromArray :config bundling); # To parse command-line arguments
	
	sub parse_SSM_file
	{
	## INITIALIZATION
		# Get arguments
		my ($raw_opt, $actions) = @_;
		
		# Assemble a context hash to pass along
		my $context = {
			ACTIONS	=>	$actions,
			RAW_OPTIONS	=>	$raw_opt
		};
		my %actions = %{ $actions };
		
		### CALL THE BEGIN BLOCK
		###
		try_action $context, 'BEGIN';
		###
		###
		
		
		# Parse command line options into the options(opt) hash
		$context->{OPTIONS} //= {};
		GetOptionsFromArray($raw_opt, $context->{OPTIONS},
			'in|i||vcf=s',
			'out|o=s',
			'gene|g=s',
			'project|p=s',
			'offline|f',
			'help|h'
		);
		my %opt = %{ $context->{OPTIONS} };


		my $input = *STDIN;# Open input file
		if( $opt{in} )  { open_input( $input, full_path($opt{in}) ); }


		my $output = *STDOUT; # Open output file
		if ( $opt{out} )  { open_output( $output, full_path($opt{out}) ); }
		
		# Update context
		$context->{INPUT} = $input;
		$context->{OUTPUT} = $output;

		### CALL THE HELP BLOCK
		### Check if user asked for help
		if( $opt{help} ) { try_action $context, 'HELP' , sub {croak "No help available yet"}; }
		###
		###

	## LOCAL DATA INITIALIZATION

		# Get gene's data
		my %gene = %{ get_gene_data($opt{gene}, $opt{offline}) };
		# Get project's data
		my %project = %{ get_project_data($opt{project}) };
		# Get header fields
		my $headers = get_vcf_headers($input);

		# Update context
		$context->{GENE} = \%gene;
		$context->{PROJECT} = \%project;
		$context->{HEADERS} = $headers;
		
		###
		### CALL THE START BLOCK
		try_action $context, 'START';
		###
		###

		
	## MAIN QUERY
		
		while(my $line = get_vcf_line($input)) # Get mutation by mutation
		{
			# Update context
			$context->{LINE} = $line;
			
			###
			### CALL THE LOOP ANY BLOCK
			try_action $context, 'ANY' ;
			###
			###
			
			# Check for specified gene and project
			if ($line =~ $gene{regexp} and $line =~ $project{regexp})
			{
				###
				### CALL THE LOOP MATCH BLOCK
				try_action $context, 'MATCH';
				###
				###
			}
			else {
				###
				### CALL THE LOOP NO_MATCH BLOCK
				try_action $context, 'NO_MATCH';
				###
				###
			}
		}
		
		###
		### CALL THE END BLOCK
		try_action $context, 'END';
		###
		###
	}#-----------------------------------------------------------
	
	
#============================================================

1; # Return success
