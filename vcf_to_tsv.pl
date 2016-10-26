#! /usr/bin/perl

my $doc_str = <<END;

Usage: ./vcf_parser [--in=<vcffile>] [--out=<outfile>]

===========================
VCF to TSV format converter
===========================

Script to transform a VCF file to a TSV file
Command-line arguments:

	-i, --in, --vcf
		Name of the input vcf file.
		If not present, input from STDIN.
		
	-o, --out
		Name of the output file (optional).
		If not present, outputs to STDOUT.
		
	-h, --help
		Print this text and exit.

Author: Andrés García García @ 12-Jul-2016

END

use Getopt::Long; # To parse command-line arguments


#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Declare variables to hold command-line arguments
my $vcffile_name = ''; my $out_name = ''; my $help = '';
GetOptions(
	'in|i|vcf=s' => \$vcffile_name,
	'o|out=s' => \$out_name,
	'h|help' => \$help
	);


# Check if user asked for help or he didn't chose an input
if($help)	{ die $doc_str; }

# Open input file
my $vcffile = STDIN;
if($vcffile_name)
{
	# Open input file
	open ($vcffile, "<", $vcffile_name)
		or die "Can't open $vcffile_name : $!";
}

# Open output file
my $out = STDOUT;
if ($out_name)
{
	open ($out, ">", $out_name)
		or die "Can't open $out_name : $!";
}

# Output operation and removal of extra #'s'
while (my $line = <$vcffile>)
{
    chomp $line;
    if ($line =~ /^#(.*)/)
    {
        print $out "$1\n";
    }
    else
    {
        print $out "$line\n";
    }
}

#===============>> END OF MAIN ROUTINE <<=====================


