#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./parse_mutations.pl [--in=<vcffile>] [--out=<outfile>] [--help]

================================
 Parse mutations from VCF file
================================

Receives a VCF with the SSM data from the ICGC data releases and gets information about the mutations from the Ensembl database through a direct online query with the Ensembl Perl API.
Command-line arguments:

	-i, --in, --vcf
		Name of the input VCF file.
		If not present, input from standard input.
		
	-o, --out
		Name of the output file.
		If not present output to standard output.
	
	-h, --help
		Show this text and exit.
	
Author: Andrés García García @ Oct 2016.

END


use Getopt::Long; # To parse command-line arguments
use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Declare variables to hold command-line arguments
	my $inputfile_name = ''; my $out_name = ''; my $help;
	GetOptions(
		'i|in|vcf=s' => \$inputfile_name,
		'o|out=s' => \$out_name,
		'h|help' => \$help
		);


	my $inputfile = STDIN;# Open input file
	if($inputfile_name)  { open_input($inputfile, $inputfile_name); }


	my $out = STDOUT; # Open output file
	if ($out_name)  { open_output($out, $out_name); }

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }
	
## LOCAL DB DATA INITIALIZATION

	# Get the fields available in the TSV file
	my @fields = get_vcf_line($inputfile);
	print_array(\@fields, "Fields");
	# Get the column position of the important fields
	# Get the column position of the important fields
	my %fields = (
		'INFO'	=>	get_col_number('INFO', \@fields), # The column that specifies the genes affected
		'ID'	=>	get_col_number('ID', \@fields), # Mutation ID
		'CHROM'	=>	get_col_number('CHROM', \@fields), # The column that specifies chromosome number
		'POS'	=>	get_col_number('POS', \@fields), # Position in chromosome
		'REF'	=>	get_col_number('REF', \@fields), # Sequence or base in the reference, this is the one we care to compare
		'ALT'	=>	get_col_number('ALT', \@fields), # Alternate sequence. This is found instead of the reference
	);
	
## COUNTERS INITIALIZATION
	
	my $total_mutations = 0;
	my $coding_mutations = 0;
	my %mutations_with_phase = ( 0 => 0, 1 => 0, 2 => 0 );
	my %mutations = (); # Associates ID to a mutation data hash
	my %genes = (); # Associates gene ID's to a list of the associated mutation ID's


## WEB DATA INITIALIZATION
	
	# Initialize a connection to the db.
	my $connection = ensembldb_connect();
	my $slice_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Slice' );
	
## DATA QUERY
	
while(my @line = get_vcf_line($inputfile)) # Get mutation by mutation
{
	$total_mutations++;
	
	# Read the local data (ICGC)
	my %mutation = (
		'ID'	=>	$line[ $fields{'ID'} ],
		'CHROM'	=>	$line[ $fields{'CHROM'} ],
		'POS'	=>	$line[ $fields{'POS'} ],
		'REF'	=>	$line[ $fields{'REF'} ],
		'ALT'	=>	$line[ $fields{'ALT'} ],
		);
	
	my $INFO = $line[ $fields{'INFO'} ];
	
	# Convert the position to GRChr38 assembly coordinates
	my $seq_length = length $mutation{'REF'};
	my ($mapped_pos_in_chrom, $mapped_end_pos) = map_GRChr37_to_GRChr38($slice_adaptor, $mutation{'CHROM'}, $mutation{'POS'}, $seq_length);
	
	#Print mutation data
	print "\nMUTATION:$mutation{'ID'} @ chromosome $mutation{'CHROM'}, position (GRChr38:$mapped_pos_in_chrom-$mapped_end_pos) ($mutation{'REF'} > $mutation{'ALT'}).\n";
	
	# Get the genes affected for the current mutation
	my @genes = ( $INFO =~ /(ENSG[0-9]+)/g );
	@genes = uniq(\@genes);
	#print_array(\@genes, "Genes affected");
	
	foreach my $gene_ID (@genes)
	{
		my $gene_slice;
		eval { $gene_slice = $slice_adaptor->fetch_by_gene_stable_id($gene_ID, 3); };
		if ($@) { warn $@; }
		else
		{
			#Get information about the slice
			my $coord_sys  = $gene_slice->coord_system()->name();
			my $seq_region = $gene_slice->seq_region_name();
			my $start      = $gene_slice->start();
			my $end        = $gene_slice->end();
			my $strand     = $gene_slice->strand();
			my $length     = $end-$start;
			
			#Get the sequence
			my $gene_sequence = $gene_slice->subseq(1, 100);
			
			print "\tGENE: $gene_ID @ $coord_sys $seq_region ($start-$end) length:$length, strand:$strand\n";
			#print "\tSEQUENCE:$gene_sequence\n";
			
			# Get all exons
			my @exons = @{$gene_slice->get_all_Exons()};
			
			# Report the found exons
			my @exon_IDs = ();
			foreach my $exon (@exons) { push @exon_IDs, $exon->stable_id(); }
			#print_array(\@exon_IDs, "\t\tCorresponding exons");
			
			# Search for the mutation in the exons
			foreach my $exon (@exons)
			{
				my $exon_slice = $exon->{'slice'};
				
				$coord_sys  = $exon->coord_system_name();
				$seq_region = $exon->seq_region_name();
				my $seqname = $exon->seqname();
				$start      = $exon->seq_region_start();
				$end        = $exon->seq_region_end();
				my $length = $end-$start;
				$strand     = $exon->seq_region_strand();
				my $exon_id = $exon->stable_id();
				my $phase = $exon->phase();
				
				# Print information about the exons
				print "\t\tEXON: $exon_id @ $coord_sys $seq_region ($start-$end), length $length, strand: $strand, phase: $phase";
					if ($phase == -1) { print " (NON-CODING EXON)\n"; }
					else 
					{ 
						print " (CODING EXON)\n"; 
					}
				
				# Check if the mutation resides in the current exon
				if (my $position_in_exon = contains($exon, $mapped_pos_in_chrom))
				{				
					# Report match
					$coding_mutations++ unless ($phase == -1);
					
					print "\n\t\t-----------------------------------------------------------------\n";
					print "\t\tMATCH: The exon (@ $start-$end) contains in $position_in_exon the mutation @ $mapped_pos_in_chrom-$mapped_end_pos\n";
					
					my $sequence_in_exon = substr($exon_slice->seq(), ($position_in_exon-1)-6, ($seq_length)+12);
					my $sequence_in_chrom = $slice_adaptor->fetch_by_region( 'chromosome', $seq_region, $mapped_pos_in_chrom-1, $mapped_end_pos+1)->seq();
					print "\t\tMATCH: ICGC reference: $ref_seq, Ensembl reference: $sequence_in_chrom, Exon reference: $sequence_in_exon\n";
					print "\n\t\t-----------------------------------------------------------------\n";
					
					# Get phase of mutation
					my $mutation_phase = ($phase + ($mapped_pos_in_chrom-$start)) % 3;
					$mutations_with_phase{$mutation_phase}++ unless ($phase == -1);
					
					print "\t\tMATCH: Added mutation with phase $mutation_phase to count.\n" unless ($phase == -1);
					print "\t\tMATCH: Current counts: TOTAL MUTATIONS: $total_mutations, CODING MUTATIONS: $coding_mutations, Phase of the mutations (0, 1, 2) : ($mutations_with_phase{0}, $mutations_with_phase{1}, $mutations_with_phase{2})\n";
				}
				else 
				{ 
					print "\t\tThe exon ($start-$end) doesn't contain the mutation @ $mapped_pos_in_chrom"; 
					if ($start > $mapped_pos_in_chrom) { print " (mutation is UPSTREAM)\n"; }
					elsif ($end < $mapped_pos_in_chrom) { print " (mutation is DOWNSTREAM)\n"; }
					else { print " Mmm, something is wrong!!!!!"; }
				}
			}
		}
	}
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

sub map_GRChr37_to_GRChr38
# Maps a coordinate in the reference assembly GRChr37 to GRChr38
{
	my $chromosome = shift;
	my $position = shift;
	
	use HTTP::Tiny; # To use web requests
	my $http = HTTP::Tiny->new();
 
	my $server = 'http://rest.ensembl.org';
	my $ext = "/map/human/GRCh37/$chromosome:$position..$position:1/GRCh38?";
	my $response;
	do
	{
		$response = $http->get($server.$ext, 
								{	headers => { 
										'Content-type' => 'application/json' 
										}
								}
							  );
		print STDERR "Query failed!\n" unless $response->{success};
	} while ( !($response->{success}) );
	
	
	use JSON;
	if(length $response->{content}) 
	{
		my $hash = decode_json($response->{content});
		my %mapped = %{ ${{ %{ @{ ${{ %{$hash} }}{'mappings'} }[0] } }}{'mapped'} };
		return $mapped{'end'};
	}
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

sub map_GRChr37_to_GRChr38
# Maps a coordinate in the reference assembly GRChr37 to GRChr38
{
	my $slice_adaptor = shift;
	my $chromosome = shift;
	my $position = shift;
	my $length = shift;
	
	my $begin_slice = $position;
	my $end_slice = $position + ($length - 1);
	
	$slice = @{ fetch_GRCh38_slice_from_GRCh37_region($slice_adaptor, $chromosome, $begin_slice, $end_slice) }[0];
	
	return ($slice->start(), $slice->end());
}#-----------------------------------------------------------

sub contains
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $exon = shift;
	my $mapped_pos_in_chrom = shift;
	
	$exon_start = $exon->seq_region_start();
	$exon_end = $exon->seq_region_end();
	if ($exon_start < $mapped_pos_in_chrom && $mapped_pos_in_chrom < $exon_end)
	{
		return $mapped_pos_in_chrom - $exon_start + 1;
	}
	
	else { return 0; }
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
      $slice = $segment->to_Slice();
	  push @slices, $slice;
	}
	
	return \@slices;
}#-----------------------------------------------------------
