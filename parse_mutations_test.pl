#! /usr/bin/perl 

my $doc_str = <<END;

Usage: ./parse_mutations.pl [--in=<vcffile>] [--out=<outfile>] [--project=<ICGC project name>] [--help]

================================
 Parse mutations from VCF file
================================

Receives a VCF with the SSM data from the ICGC data releases and gets information about the mutations from the Ensembl database through a direct online query with the Ensembl Perl API.
If project is specified, only those found in the project will be analized.
Command-line arguments:

	-i, --in, --vcf
		Name of the input VCF file.
		If not present, input from standard input.
		
	-o, --out
		Name of the output file.
		If not present output to standard output.
		
	-p, --project, --projects
		Name of an ICGC project name, or a comma-separated list of names.
		Filters by those who mention it in the mutation's INFO.
	
	-h, --help
		Show this text and exit.
	
Author: Andrés García García @ Oct 2016.

END


use Getopt::Long; # To parse command-line arguments
use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Data::Dumper; # To preety print hashes easily
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Declare variables to hold command-line arguments
	my $inputfile_name = ''; my $out_name = ''; my $project = 'all'; my $help;
	GetOptions(
		'i|in|vcf=s' => \$inputfile_name,
		'o|out=s' => \$out_name,
		'p|project|projects=s' => \$project,
		'h|help' => \$help
		);


	my $inputfile = STDIN;# Open input file
	if($inputfile_name)  { open_input($inputfile, $inputfile_name); }


	my $out = STDOUT; # Open output file
	if ($out_name)  { open_output($out, $out_name); }
	
	# Check if some project was specified
	my @projects = split(/,/, $project);

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }

	
	
## LOCAL DB DATA INITIALIZATION

	# Get the fields available in the TSV file
	my %fields = get_fields_from($inputfile, 
								'INFO', # The column that specifies the genes affected
								'ID', # Mutation ID
								'CHROM', # The column that specifies chromosome number
								'POS', # Position in chromosome
								'REF', # Sequence or base in the reference, this is the one we care to compare
								'ALT' # Alternate sequence. This is found instead of the reference
								);
	

	
## COUNTERS INITIALIZATION
	my %counters = ('total' => 0);
	foreach my $project (@projects)
	{
		$counters{$project} = {'TOTAL' => 0,
							   'INTERGENIC' => 0,
							   'INTRONIC' => 0,
							   'NON_CODING_EXON' => 0,
							   'CODING' => { 0 => 0, 1 => 0, 2 => 0}
							   };
	}

	
## WEB DATA INITIALIZATION
	
	# Initialize a connection to the db.
	my $connection = ensembldb_connect();
	my $slice_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Slice' );


	
## DATA QUERY
	
	# Print table header to output
	my @output_header = ( 'MUT_ID', 'POSITION', 'MUTATION', 'GENES_OVERLAPPED', 'GENES_AFFECTED', 'PHASE', 'COUNTERS', 'PROJECT' );
	print join("\t", @table_line)."\n";
	
	
while(my @line = get_vcf_line($inputfile)) # Get mutation by mutation
{
	$counters{'total'}++;
	
	my $INFO = $line[ $fields{'INFO'} ];
	
	# If projects where specified, check if the mutation belongs to any of them
	my @projects_matched = search_patterns(\@projects, $INFO);
	my $all_projects = $projects[0] eq 'all';
	next unless (@projects_matched or $all_projects); # Skip if not in a specified project
	
	push( @projects_matched, 'all' ) if ($all_projects);
	foreach my $project (@projects_matched)
	{
		$counters{$project}{'total'}++;
	}
	
	# Read the local data (ICGC)
	my %mutation = %{ read_line_as_hash(\@line, \%fields) };
	$mutation{'LENGTH'} = length $mutation{'REF'};
	$mutation{'PHASE'} = 'UNDEF';
	
	# Fetch a slice with the mutation
	my $end_slice = $mutation{'POS'} + ($mutation{'LENGTH'} - 1);
	$mutation_slice = @{ fetch_GRCh38_slice_from_GRCh37_region($slice_adaptor, $mutation{'CHROM'}, $mutation{'POS'}, $end_slice) }[0];
	$mutation{'GRCh38_POS'} = $mutation_slice -> start();
	
	#Print mutation data
	my $to = $mutation{'POS'} + $seq_length -1;
	$mapped_end_pos = $mutation{'GRCh38_POS'} + $seq_length -1;
	print "\nMUTATION:$mutation{'ID'} @ chromosome $mutation{'CHROM'}, position (GRCh37:$mutation{'POS'}-$to GRCh38:$mutation{'GRCh38_POS'}-$mapped_end_pos) ($mutation{'REF'} > $mutation{'ALT'}).\n";
	
	# Get the genes that overlap the mutation
	my @overlapped_genes = $mutation_slice -> get_all_Genes();
	$mutation{'OVERLAPPED'} = join(',', get_stable_ids(\@overlapped_genes));
	
	# Get the genes affected for the current mutation
	my @affected_genes = ( $INFO =~ /(ENSG[0-9]+)/g );
	@affected_genes = uniq(\@affected_genes);
	$mutation{'AFFECTED'} = join(',', @affected_genes);
	
	# Check if it is an intergenic mutation
	unless (@overlapped_genes)
	{
		foreach my $project (@projects_matched)
		{
			$counters{$project}{'intergenic'}++;
			$mutation{'PHASE'} = 'INTERGENIC';
			#print "Mutation $mutation{'ID'} doesn't overlap any gene, so it is INTERGENIC.\n";
		}
	}
	
	my $found_in_exon = undef;
	foreach my $gene (@overlapped_genes)
	{
		my $gene_slice;
		eval { $gene_slice = $slice_adaptor->fetch_by_gene_stable_id($gene_ID, 3); };
		if ($@) { warn $@; }
		else
		{		
			%gene = ( 'ID' => $gene_ID,
					  'COORD_SYS' => $gene_slice -> coord_system_name(),
					  'SEQ_REGION' => $gene_slice -> seq_region_name(),
					  'START' => $gene_slice -> start(),
					  'END' => $gene_slice -> end(),
					  'LENGTH' => $gene_slice -> length(),
					  'STRAND' => $gene_slice -> strand()
					  );
			#print "\tGENE: $gene{'ID'} @ $gene{'COORD_SYS'} $gene{'SEQ_REGION'} ($gene{'START'}-$gene{'END'}) length:$gene{'LENGTH'}, strand:$gene{'STRAND'}\n";
			
			# Get all exons
			my @exons = @{$gene_slice->get_all_Exons()};
			
			# Search for the mutation in the exons
			foreach my $exon (@exons)
			{
				my $exon_slice = $exon->{'slice'};
				
				%exon = ( 'ID' => $exon -> stable_id(),
						  'COORD_SYS'	=> $exon_slice -> coord_system_name(),
						  'SEQ_REGION'	=> $exon_slice -> seq_region_name(),
						  'START'		=> $exon_slice -> start(),
						  'END'			=> $exon_slice -> end(),
						  'LENGTH'		=> $exon_slice -> length(),
						  'STRAND'		=> $exon_slice -> strand(),
						  'PHASE'		=> $exon -> phase()
						  );
				
				# Print information about the exons
# 				print "\t\tEXON: $exon{'ID'} @ $exon{'COORD_SYS'} $exon{'SEQ_REGION'} ($exon{'START'}-$exon{'END'}), length $exon{'LENGTH'}, phase: $exon{'PHASE'}";
# 					if ($exon{'PHASE'} == -1) { print " (NON-CODING EXON)\n"; }
# 					else 
# 					{ 
# 						print " (CODING EXON)\n"; 
# 					}
				
				# Check if the mutation resides in the current exon
				if (my $position_in_exon = contains($exon->start(), $exon->end(), $mutation{'GRCh38_POS'}))
				{	
					# Found, declare the end of the exons loop
					$found_in_exon = 1;
					last;
					
					# Report match
					#print "\n\t\t-----------------------------------------------------------------\n";
					#print "\t\tMATCH: The exon (@ $exon{'START'}-$exon{'END'}) contains in $position_in_exon the mutation @ $mapped_pos_in_chrom-$mapped_end_pos\n";
					
					#my $sequence_in_exon = substr($exon_slice->seq(), ($position_in_exon-1)-6, ($exon{'LENGTH'})+12);
					#my $sequence_in_chrom = $slice_adaptor->fetch_by_region( 'chromosome', $exon{'SEQ_REGION'}, $mapped_pos_in_chrom-1, $mapped_end_pos+1)->seq();
					#print "\t\tMATCH: ICGC reference: $ref_seq, Ensembl reference: $sequence_in_chrom, Exon reference: $sequence_in_exon\n";
					#print "\n\t\t-----------------------------------------------------------------\n";
					
					# Get phase of mutation
					my $mutation_phase = ($exon{'PHASE'} + ($mapped_pos_in_chrom-$exon{'START'})) % 3;
					foreach my $project (@projects_matched)
					{
						if ($exon{'PHASE'} == -1)
						{
							$counters{$project}{'non_coding_exon'}++;
							$mutation{'PHASE'} = 'NON_CODING_EXON';
							#print "Mutation $mutation{'ID'} is in a NON-CODING EXON.\n";
						}
						else	
						{ 
							$counters{$project}{'coding'}{$mutation_phase}++;
							$mutation{'PHASE'} = $mutation_phase;
							#print "Mutation $mutation{'ID'} is in a CODING exon with PHASE $mutation_phase.\n";		
						}
					}
				}
				
				else # Isn't contained in the exon
				{ 
# 					print "\t\tThe exon ($exon{'START'}-$exon{'END'}) doesn't contain the mutation @ $mapped_pos_in_chrom"; 
# 					if ($start > $mapped_pos_in_chrom) { print " (mutation is UPSTREAM)\n"; }
# 					elsif ($end < $mapped_pos_in_chrom) { print " (mutation is DOWNSTREAM)\n"; }
#					else { print " Mmm, something is wrong!!!!!"; }
				}
			}
		}
		
		# Stop searching if mutation was already found
		last if ($found_in_exon);
	}
	
	# Mutation wasn't found in gene exons, so it is intronic
	unless ($found_in_exon)
	{
		foreach my $project (@projects_matched)
		{
			$counters{$project}{'intronic'}++;
			$mutation{'PHASE'} = 'INTRONIC';
			#print "Mutation $mutation{'ID'} isn't found in any exon, so it is INTRONIC.\n";
		}
	}
	
	# Check the status of the counters
	#print_hash(\%counters, "Counts");
	
	# Print gathered data
	@table_line = ( $mutation{'ID'}, "CHR$mutation{'CHROM'}\@$mutation{'GRCh38_POS'}",
					"$mutation{'REF'}>$mutation{'ALT'}", $mutation{'OVERLAPPED'}, 
					$mutation{'AFFECTED'}, $mutation{'PHASE'} 
				  );
	my @counters = ("total=$counters{'total'}");
	foreach my $project (@projects)
	{
		my @project_counters = ("project_total($project)=$counters{$project}{'total'}",
							 "intergenic($project)=$counters{$project}{'intergenic'}",
							 "intronic($project)=$counters{$project}{'intronic'}",
							 "non_coding_exon($project)=$counters{$project}{'non_coding_exon'}",
							 "phase_0($project)=$counters{$project}{'coding'}{0}",
							 "phase_1($project)=$counters{$project}{'coding'}{1}",
							 "phase_2($project)=$counters{$project}{'coding'}{0}"
							 );
		push( @counters, @project_counters );
	}
	push ( @table_line, join(',', @counters) );
	push ( @table_line, join(',', @projects_matched) );
	print join("\t", @table_line)."\n";
}

#===============>> END OF MAIN ROUTINE <<=====================
 
#	===========
#	Subroutines
#	===========

sub ensembldb_connect
# Initialize a connection to the db
{
  # Initialize a registry object
  my $registry = 'Bio::EnsEMBL::Registry';

  # Connect to the Ensembl database
  print STDERR "Waiting connection to database...\n";
  $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
      -user => 'anonymous'
      );
  print STDERR "Connected to database\n";
  
  return $registry;
}#------------------------------------------------------ 

sub get_vcf_line
# Get a line from a VCF file splitted in an array
{
	my $vcffile = shift;
	
	# Skip comments
	my $line;
	do	{ $line = <$vcffile>; }
	while($line =~ /^##.*/);
		
	# Check wether you are in the headers line
	if ($line =~ /^#(.*)/) { $line = $1; }
	
	my @fields = split(/\t/, $line);
	chomp @fields;
	return @fields;
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
	
	die "Column '$colname' not found!\n!";
}#-----------------------------------------------------------

sub open_input
# Prints given message and opens input file
# Exit with error if it fails to open the file
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open input file
	print $message;
	open ($file_handler, "<", $file_name)
		or die "Can't open $file_name for input : $!";
}#-----------------------------------------------------------

sub open_output
# Prints given message and opens file for output
# Exit with error if it fails to open the file
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open output file
	print $message;
	open ($file_handler, ">", $file_name)
		or die "Can't open $file_name for output : $!";
}#-----------------------------------------------------------

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
}#-----------------------------------------------------------

sub print_array
# Prints the content of the passed array
{
	my @array = @{shift()};
	my $name = shift;
	
	print "$name: (" . join(',', @array) . ")\n";
}#-----------------------------------------------------------

sub print_hash
# Prints the content of the passed hash
{
	my %hash = %{shift()};
	my $name = shift;
	
	print "$name: ".Dumper \%hash;
}#-----------------------------------------------------------

sub uniq
# Remove repeated entries from array
{
	my @array = @{shift()};
	my %seen;
	
	return grep !($seen{$_}++), @array;
}#-----------------------------------------------------------

sub any
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $key = shift;
	my @array = @{shift()};
	
	foreach my $i (@array)
	{
		if ($key eq $i)
		{
			return 1;
		}
	}
	return 0;
}#-----------------------------------------------------------

sub map_GRCh37_to_GRCh38
# Maps a coordinate in the reference assembly GRCh37 to GRCh38
{
	my $slice_adaptor = shift;
	my $chromosome = shift;
	my $position = shift;
	my $length = shift;
	
	my $begin_slice = $position;
	my $end_slice = $position + ($length - 1);
	
	my $slice = @{ fetch_GRCh38_slice_from_GRCh37_region($slice_adaptor, $chromosome, $begin_slice, $end_slice) }[0];
	
	my @return = ();
	eval { @return = ($slice->start(), $slice->end()); };
	if ($@) 
	{ 
		warn $@;
		return (-1, -1);
	}
	return @return;
}#-----------------------------------------------------------

sub contains
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $start = shift;
	my $end = shift;
	my $mapped_pos_in_chrom = shift;
	
	if ($start < $mapped_pos_in_chrom && $mapped_pos_in_chrom < $end)
	{
		return $mapped_pos_in_chrom - $start + 1;
	}
	
	else { return undef; }
}#-----------------------------------------------------------

sub fetch_GRCh38_slice_from_GRCh37_region
# Fetches a slice in the GRCh38 assembly from GRCh37 coordinates
{
	my $slice_adaptor = shift;
	my $chromosome = shift;
	my $begin = shift;
	my $end = shift;
	
	# Fetch slice in the GRCh37 assembly
	my $GRCh37_slice = $slice_adaptor->fetch_by_region( 'chromosome', $chromosome, $begin, $end, '1', 'GRCh37' );
	
	# Make a projection onto the GRCh38 coordinates
	my $projection = $GRCh37_slice->project('chromosome', 'GRCh38');
	my @slices = ();

	foreach my $segment ( @{$projection} ) 
	{
      my $slice = $segment->to_Slice();
	  push @slices, $slice;
	}
	
	return \@slices;
}#-----------------------------------------------------------

sub get_fields_from
# returns a dictionary with the positions of the fields
{
	my $inputfile = shift; # The input file
	my @fields = ();	# The fields to search
	while (my $field = shift) { push @fields, $field; }
	
	# Get the fields
	my @fields = get_vcf_line($inputfile);
	
	# Get the column position of the searched fields
	my %fields = ();
	foreach my $field (@fields)
	{
		$fields{$field} = get_col_number($field, \@fields);
	}
	
	return %fields;
}#-----------------------------------------------------------

sub search_patterns
# Usage: search_patterns(\LIST, STRING)
# Retuns the elements in LIST that are a substring in STRING
{
	my @patterns = @{ shift() };
	my $string = shift;
	
	my @matches = ();
	foreach my $pattern (@patterns)
	{
		my $re = qr/$pattern/;
		push( @matches, $pattern ) if ($string =~ /$re/);
	}
	
	return @matches;
}#-----------------------------------------------------------

sub get_stable_ids
# Usage: get_stable_ids(\@features);
# Retuns the list with the stable id of the features in the array
{
	my @features = @{shift()};
	
	my @stable_ids = ();
	foreach my $feature (@features)
	{
		push( @stable_ids, $feature -> stable_id() );
	}

	return @stable_ids;
}#-----------------------------------------------------------

sub read_line_as_hash
# Retuns the hash with the header associaciated with its respective information
{
	my @line = @{shift()};
	my %headers = %{shift()};
	
	my %line = ();
	foreach my $header (keys %headers)
	{
		$line{ $header } = $line[ $headers{$header} ];
	}

	return \%line;
}#-----------------------------------------------------------