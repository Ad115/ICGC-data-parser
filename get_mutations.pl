#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./get_genes_from_tsv.pl [--in=<tsvfile>] [--out=<outfile>] [--help]

================================
Get gene sequences from tsv file
================================

Receives a tsv file with the reference information of the ICGC database and gets the sequences of the genes described there.
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
use Data::Dumper; # To print easily data structures
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;

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
	if ($out_name)  { open_output($out, $out_name); }

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }
	
	
## LOCAL DB DATA INITIALIZATION

	# Get the fields available in the TSV file
	my @fields = get_tsv_line($tsvfile);
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
	
	
## DATA QUERY
while(my @line = get_tsv_line($tsvfile)) # Get mutation by mutation
{
	$total_mutations++;
	print "\nMutation no. $total_mutations:\n";
	
	# Read the local data (ICGC)	
	my %mutation = (
		'ID'	=>	$line[ $fields{'ID'} ],
		'CHROM'	=>	$line[ $fields{'CHROM'} ],
		'POS'	=>	$line[ $fields{'POS'} ],
		'REF'	=>	$line[ $fields{'REF'} ],
		'ALT'	=>	$line[ $fields{'ALT'} ],
		
		);
	my $INFO = $line[ $fields{'INFO'} ];
	
	$mutations{ $mutation{'ID'} } = \%mutation; # Add mutation to the %mutations hash
	
	
	# Convert the position to GRChr38 assembly coordinates
	$mutation{'POS'} = map_GRChr37_to_GRChr38($mutation{'CHROM'}, $mutation{'POS'});
	my $seq_length = length $seq_length;
	my $end_pos = $mutation{'POS'} + ($seq_length-1);
	
	#Print mutation data
	print "MUTATION:$mutation{'ID'} @ chromosome $mutation{'CHROM'}, position (GRChr38:$mutation{'POS'}-$end_pos) ($mutation{'REF'} > $mutation{'ALT'}).\n";
	
	# Get the genes affected for the current mutation
	my @genes = ( $INFO =~ /(ENSG[0-9]+)/g );
	@genes = uniq(\@genes);
	print_array(\@genes, "Genes affected");
	
	foreach	my $gene (@genes)
	{
		print_hash(\%genes, "Inserting $gene in Genes ");
		if (exists $genes{$gene})	{ push @{ $genes{$gene} }, \%mutation; }
		else	{ $genes{$gene} = [ \%mutation ]; }
	}
	
	print_hash(\%genes, "Genes ");
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
