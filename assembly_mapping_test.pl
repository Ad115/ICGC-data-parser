#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./compare_ICGC_vs_ensembl.pl [--in=<tsvfile>] [--out=<outfile>] [--help]

===========================
Filtering cols in TSV files
===========================

Receives a tsv file with the reference information of the ICGC database and compares it with data obtained directly from ensembl database at the moment.
Reads the columns CHROM, POS and REF.
Command-line arguments:

	-i, --in, --tsv
		Name of the input tsv file.
		If not present, input from standard input.
		
	-o, --out
		Name of the output file.
		If not present output to standard output.
	
	-h, --help
		Show this text and exit.
	
Author: Andrés García García @ Sept 2016.

END


use Getopt::Long; # To parse command-line arguments
use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Declare variables to hold command-line arguments
	my $tsvfile_name = ''; my $out_name = ''; my $help;
	GetOptions(
		'i|in|tsv=s' => \$tsvfile_name,
		'o|out=s' => \$out_name,
		'h|help' => \$help
		);


	my $tsvfile = STDIN;# Open input file
	if($tsvfile_name)  { open_input($tsvfile, $tsvfile_name); }


	my $out = STDOUT; # Open output file
	if ($out_name)  { open_output($out, $out_name,); }

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }
	
## LOCAL DB DATA AQUISITION

	# Get the fields available in the TSV file
	my @fields = get_tsv_line($tsvfile);
	# Get the column position of the important fields
	my $chrom_pos = get_col_number('CHROM', \@fields); # The column that specifies chromosome number
	my $pos_in_chrom_pos = get_col_number('POS', \@fields); # Position in chromosome
	my $ref_seq_pos = get_col_number('REF', \@fields); # Sequence or base in the reference, this is the one we care to compare


## WEB DATA AQUISITION
	
	# Initialize a connection to the db.
	my $connection = ensembldb_connect();
	my $slice_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Slice' );
	
## Experiment: get the available coord. systems
	my $cs_adaptor = $connection->get_adaptor( 'Human', 'Core', 'CoordSystem' );
	my @coord_systems = @{ $cs_adaptor->fetch_all() };
	foreach $cs (@coord_systems) {
		printf "Coordinate system: %s %s\n", $cs->name(), $cs->version;
	}
	
## DATA COMPARISON

my $match_count = 0;
my $query_count = 0;
while(my @line = get_tsv_line($tsvfile))
{
	# Read the local data (ICGC)
	my $chrom = $line[$chrom_pos];
	my $pos_in_chrom = $line[$pos_in_chrom_pos];
	my $ref_seq = $line[$ref_seq_pos];
	my $seq_length = length $ref_seq;
	
	
	# Convert the position to GRChr38 assembly coordinates
	my $mapped_pos_in_chrom = map_GRChr37_to_GRChr38($chrom, $pos_in_chrom);
	
	
	# Read the web data (ENSembl)
	my $mapped_begin_slice = $mapped_pos_in_chrom-1;
	my $mapped_end_slice = $mapped_pos_in_chrom + ($seq_length - 1)+1;
	my $begin_slice = $pos_in_chrom-1;
	my $end_slice = $pos_in_chrom + ($seq_length - 1) +1;

 	my $mapped_slice = $slice_adaptor->fetch_by_region( 'chromosome', $chrom, $mapped_begin_slice, $mapped_end_slice);
	my $unmapped_slice = $slice_adaptor->fetch_by_region( 'chromosome', $chrom, $begin_slice, $end_slice, '1', 'GRCh37' );


	# Get the sequence in ensembl
	my $unmapped_sequence = $unmapped_slice->seq();
	my $mapped_sequence = $mapped_slice->seq();
	
	print "Mapped to GRCh38 by Ensembl REST API:\t\t$mapped_sequence\t:\t$ref_seq\t@ ($mapped_begin_slice-$mapped_end_slice)\n";
	print "Directly queried in GRCh37 from Perl API:\t\t$unmapped_sequence\t:\t$ref_seq\t@ ($begin_slice-$end_slice)\n";
	
	
	##########################################################################################################
	#EXPERIMENTAL
	my $projection = $unmapped_slice->project('chromosome', 'GRCh38');
	my $slice = ""; my $sequence = ""; my $start = ""; my $end = "";

	foreach my $segment ( @{$projection} ) 
	{
      $slice = $segment->to_Slice();
	  $sequence = $slice->seq(); $start = $slice->start(); $end = $slice->end();
      print "Slice mapped from GRCh37 to GRCh38 with Perl API:\t\t$sequence\t:\t$ref_seq\t@ ($start-$end)\n";
	}
	########################################################################################################3
	# And all that may be resumed in the following...
	$slice = @{ fetch_GRCh38_slice_from_GRCh37_region($slice_adaptor, $chrom, $begin_slice, $end_slice) }[0];
	
	$sequence = $slice->seq(); $start = $slice->start(); $end = $slice->end();
	print "Mapping with function resuming previous steps:\t\t$sequence\t:\t$ref_seq\t@ ($start-$end)\n";
	########################################################################################################3
	
	
	
	
	$sequence =~ /\b[ACGT](.*?)[ACGT]\b/;
	$sequence = $1;
	print "$sequence\t:\t$ref_seq\n";
	
	# They match?
	if ($sequence eq $ref_seq)
	{
		$match_count++;
		print "MATCH! ";
	}
	else { print "Not a match. "; }
	
	$query_count++;
	print "Matched: $match_count, Lines queried: $query_count\n\n";
}

#===============>> END OF MAIN ROUTINE <<=====================
 
#	===========
#	Subroutines
#	===========

sub ensembldb_connect
# Initialize a connection to the db
{
  print STDERR "Waiting connection to database...\n";
  
  # Initialize a registry object
  my $registry = 'Bio::EnsEMBL::Registry';

  # Connect to the Ensembl database
  $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
      -user => 'anonymous'
      );
  
  print STDERR "Connected to database...\n";
  
  return $registry;
}#------------------------------------------------------ 

sub get_tsv_line
# Get a line of a TSV file already splitted in an array
{
	my $tsvfile = shift;
	
	# Skip comments
	my $line;
	do	{ $line = <$tsvfile>; }
	while($line =~ /^#.*/);
		
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
	my $message = shift;
	
	print $message;
	foreach my $i (0..$#array)
	{
		print "$array[$i]\n";
	}
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
	my @slices = (); my $sequence = ""; my $start = ""; my $end = "";

	foreach my $segment ( @{$projection} ) 
	{
      $slice = $segment->to_Slice();
	  push @slices, $slice;
	}
	
	return \@slices;
}#-----------------------------------------------------------
