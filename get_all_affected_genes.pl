#! /usr/bin/perl 

my $doc_str = <<END;

Usage: ./get_gene_info.pl [--gene=<genename>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--help]

========================
 Get all affected genes
========================

Searches through input file for gene identifiers

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

	my $out = STDOUT; # Open output file
	if ($out_name)  { open_output($out, $out_name); }
	
	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }
	
	
## MAIN QUERY
	my @genes = `grep -P -o ENSG[0-9.]+ < $inputfile_name | sort | uniq`;
	print $out join('', @genes);
	
#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


#	===========
#	Subroutines
#	===========

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
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