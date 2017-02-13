#! /usr/bin/perl 

my $doc_str = <<END;

Usage: ./get_all_projects.pl [--in=<vcffile>] [--out=<outfile>] [--help]

=================
 Get all projects
=================

Searches through ICGC's simple-somatic-mutation aggregated file for cancer projects.

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
use Data::Dumper; # To preety print hashes easily
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Declare variables to hold command-line arguments
	my $inputfile_name = ''; my $out_name = '';
	my $help;
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
	
##  DATA INITIALIZATION
	
## MAIN QUERY
	my @projects = ();
	while(my $line = get_vcf_line($inputfile)) # Get mutation by mutation
	{
		$line =~ /OCCURRENCE=(.*?);/;
		my @occurrences = split( /,/ , $1);
		
		foreach my $occurrence (@occurrences)
		{
			my @line = split( /\t/, $line );
			my @occurrence = split( /\|/, $occurrence);
			push @projects, "$occurrence[0]";
			@projects = uniq(\@projects);
		}
	}
	print $out join( "\n", @projects). "\n";
#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


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
	while($line =~ /^##.*/);
		
	# Check wether you are in the headers line
	if ($line =~ /^#(.*)/) { $line = $1; }
	
	return $line;
}#-----------------------------------------------------------

sub get_vcf_fields
# Get a line from a VCF file splitted in fields
{
	my $vcffile = shift;
	
	# Skip comments
	my $line;
	do	{ $line = <$vcffile>; }
	while($line =~ /^##.*/);
		
	# Check wether you are in the headers line
	if ($line =~ /^#(.*)/) { $line = $1; }
	
	return split( /\t/, $line);
}#-----------------------------------------------------------

sub get_gene_id
# Query the database for the stable id of the given gene
{
  my $gene_name = shift;

  # Declare a gene adaptor to get the gene
  my $gene_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Gene' );
  # Declare a gene handler with the given gene
  my $gene = $gene_adaptor->fetch_by_display_label($gene_name);
  unless($gene) { die "ERROR: Gene '$gene_name' not found\n"; }

  # Get the gene's EnsembleStableID
  return $gene->stable_id();
}#-------------------------------------------------------

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
		print "$hash{$key}\t";
	}
	print "\n";
	
	return;
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
	return undef;
}#-----------------------------------------------------------
