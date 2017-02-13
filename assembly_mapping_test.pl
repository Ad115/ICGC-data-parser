#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./assembly_mapping_test.pl [--in=<tsvfile>] [--out=<outfile>] [--help]

=======================
 Assembly mapping test
=======================

Comparison of the output of several attempts to retrieve a sequence from a specific location in a chromosome.
Inputs a VCF file with mutation data from the ICGC, to have a reference in the GRCh37 assembly.
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
use Data::Dumper; # To preety print hashes easily
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;


#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Declare variables to hold command-line arguments
	my $input_name = ''; my $output_name = ''; my $help;
	GetOptions(
		'i|in|tsv=s' => \$input_name,
		'o|out=s' => \$output_name,
		'h|help' => \$help
		);

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }

	my $input = STDIN;# Open input file
	if($input_name)  { open_input($input, $input_name); }


	my $output = STDOUT; # Open output file
	if ($output_name)  { open_output($output, $output_name); }
	
## LOCAL DB DATA AQUISITION

	# Get the fields available in the TSV file
	my %fields = get_fields_from($input,
								'CHROM', # The column that specifies chromosome number
								'POS', # Position in chromosome
								'REF', # Sequence or base in the reference, this is the one we care to compare
								);

## WEB DATA AQUISITION
	
	# Initialize a connection to the db.
	my $connection = ensembldb_connect();
	my $slice_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Slice' );
	
	# Get the available coord. systems
	my @coord_systems = @{ $connection
							-> get_adaptor( 'Human', 'Core', 'CoordSystem' )
							-> fetch_all() 
						};
	print $output "Available coordinate systems:\n";
	foreach my $cs (@coord_systems) 
		{ printf $output "\t%s %s\n", $cs->name(), $cs->version; }
	
## DATA COMPARISON
	
	my @output_fields = ('ICGC_data', 'fetch_GRCh37(EnsemblPerlAPI)', 'to_GRCh38(EnsemblPerlAPI)', 'to_GRCh38(EnsemblREST_API)');
	output_array_as_tsv(\@output_fields);
	
	while(my @line = get_vcf_fields($input))
	{
		# Read the local data (ICGC)
		my %ICGC = (
			'CHROM' => $line[ $fields{'CHROM'} ],
			'POS' => $line[ $fields{'POS'} ],
			'SEQ' => $line[ $fields{'REF'} ]
			);
		my $seq_length = length $ICGC{'SEQ'};
		
		# Fetch directly from GRCh37 assembly using Ensembl Perl API
		my $unmapped_seq = $slice_adaptor
							->fetch_by_region('chromosome', $ICGC{'CHROM'}, $ICGC{'POS'}-1, ($ICGC{'POS'}+$seq_length-1)+1, '1', 'GRCh37')
							->seq();
		
		# Map to GRCh38 by the Ensembl REST API
		my $PERL_mapped = PERL_map_GRCh37_to_GRCh38($ICGC{'CHROM'}, $ICGC{'POS'});
		my $PERL_mapped_seq = $slice_adaptor
								->fetch_by_region('chromosome', $ICGC{'CHROM'}, $PERL_mapped-1, ($PERL_mapped+$seq_length-1)+1)
								->seq();
		
		# Map to GRCh38 by the Ensembl REST API
		my $REST_mapped = REST_map_GRCh37_to_GRCh38($ICGC{'CHROM'}, $ICGC{'POS'});
		my $REST_mapped_seq = $slice_adaptor
								->fetch_by_region('chromosome', $ICGC{'CHROM'}, $REST_mapped-1, ($REST_mapped+$seq_length-1)+1)
								->seq();
		
		# Prepare and print output
		my %output = (
			'ICGC_data'	=>	"$ICGC{'SEQ'}\@$ICGC{'POS'}",
			'fetch_GRCh37(EnsemblPerlAPI)'	=>	"$unmapped_seq\@$ICGC{'POS'}",
			'to_GRCh38(EnsemblPerlAPI)'	=>	"$PERL_mapped_seq\@$PERL_mapped",
			'to_GRCh38(EnsemblREST_API)'	=>	"$REST_mapped_seq\@$REST_mapped"
			);
		print_fields(\%output, \@output_fields);
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
  
  print STDERR "...Connected to database\n";
  
  return $registry;
}#------------------------------------------------------ 

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

sub get_vcf_line
# Get a line from a VCF file
{
	my $vcffile = shift;

	# Skip comments
	my $line;
	do	{ $line = <$vcffile>; }
	while($line =~ /^##.*/);

	# Check wether you are in the headers line
	if ($line =~ /^#(.*)/) { $line = $1; }

	return $line;
}#-----------------------------------------------------------

sub get_vcf_fields
# Get a line from a VCF file splitted in fields
{
	my $vcffile = shift;

	return split( /\t/, get_vcf_line($vcffile));
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

sub get_fields_from
# returns a dictionary with the positions of the fields
{
	my $inputfile = shift; # The input file
	my @fields = ();	# The fields to search
	while (my $field = shift) { push @fields, $field; }

	# Get the fields
	my @fields = get_vcf_fields($inputfile);

	# Get the column position of the searched fields
	my %fields = ();
	foreach my $field (@fields)
	{
		$fields{$field} = get_col_number($field, \@fields);
	}

	return %fields;
}#-----------------------------------------------------------

sub print_fields
# USAGE: print_fields(\%hash, \@keys)
# Print orderly the values corresponding to the given keys of the hash
# Prints in TSV format
{
	my %hash = %{shift()};
	my @keys = @{shift()};

	# Print the given fields
	foreach my $key (@keys)
	{
		print $output "$hash{$key}\t";
	}
	print "\n";

	return;
}#-----------------------------------------------------------

sub REST_map_GRCh37_to_GRCh38
# Maps a coordinate in the reference assembly GRCh37 to GRCh38
# by using the Ensembl REST API
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

sub PERL_map_GRCh37_to_GRCh38
# Maps a coordinate in the reference assembly GRCh37 to GRCh38
# by using the Ensembl Perl API
{
	my $chromosome = shift;
	my $position = shift;

	my $begin_slice = $position;

	my $return = -1;
	eval {
		my $slice = @{fetch_GRCh38_slice_from_GRCh37_region($chromosome, $begin_slice, $begin_slice)}[0];
		$return = $slice->start(); 
		
	};
	if ($@)	{ warn $@; }
	return $return;
}#-----------------------------------------------------------

sub print_hash
# Prints the content of the passed hash
{
	my %hash = %{shift()};
	my $name = shift;

	print "$name: ".Dumper \%hash;
}#-----------------------------------------------------------

sub output_array_as_tsv
# Prints the content of the passed array
{
	my @array = @{shift()};

	print $output join("\t", @array) . "\n";
}#-----------------------------------------------------------