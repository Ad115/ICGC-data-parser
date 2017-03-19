#! /usr/bin/perl

package modulino;
use Exporter qw'import';
	our @EXPORT = qw'main';

#=====================================================================

our $doc_str = <<END;

Usage: filter_gene_project.pl [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--help]

============================
 Filter by gene and project
============================

Searches through input file for mutations related to the given gene and the given project.
Prints mutation recurrence data for each mutation, global and by project.

	-g, --gene
		Gene name, in display form or as stable ID.
		If present, shows only mutations that affect the gene.
		Empty gene or gene 'all' stands for mutations in any gene.

	-p, --project
		ICGC project name.
		If present, shows only mutations found in that project.
		Empty project or project 'all' stands for mutations in any project.

	-i, --in, --vcf
		Name of the input VCF file.
		The file should be in the format of the ICGC simple-somatic-mutation summary
		If not present, input from standard input.

	-o, --out
		Name of the output file.
		If not present output to standard output.

	-h, --help
		Show this text and exit.

Author: Andrés García García @ Oct 2016.

END
main(@ARGV) unless caller();

use lib '.';
    use SSM_Parser qw(:parse);
    use General qw(:general_io);
use Getopt::Long qw(:config bundling); # To parse command-line arguments

#===============>> BEGINNING OF MAIN ROUTINE <<=====================
sub main
{
## INITIALIZATION
    # Parse command line options into the options(opt) hash
    GetOptions(\%opt,
        'in|i||vcf=s',
        'out|o=s',
        'gene|g=s',
        'project|p=s',
        'help|h'
        );


    my $input = *STDIN;# Open input file
    if( $opt{in} )  { open_input( $input, full_path($opt{in}) ); }


    my $output = *STDOUT; # Open output file
    if ( $opt{out} )  { open_output( $output, full_path($opt{out}) ); }

    # Check if user asked for help
    if( $opt{help} ) { print "doc string: $doc_str\n"; print_and_exit($doc_str); }

## LOCAL DATA INITIALIZATION

	# Get fields
	my %fields = parse_fields($input);

## WEB DATA INITIALIZATION

	# Get gene's data
	my ($gene_str, $gene_re) = @{ get_simple_gene_query_data($opt{gene}) };
	# Get project's data
	my ($project_str, $project_re) = @{ get_project_query_data($opt{project}) };

	# Assemble output fields
	my @output_line_fields = qw(MUTATION_ID PROJ_AFFECTED_DONORS PROJ_TESTED_DONORS TOTAL_AFFECTED_DONORS TOTAL_TESTED_DONORS);

	# Print heading lines
	print  $output "# Project: $project_str\tGene: $gene_str\n";
	print  $output join( "\t", @output_line_fields)."\n";

## MAIN QUERY

	while(my $line = get_vcf_line($input)) # Get mutation by mutation
	{
		# Check for specified gene and project
		if ($line =~ $gene_re and $line =~ $project_re)
		{
            # Parse the mutation data
			my %mutation = %{ parse_mutation($line, \%fields, $gene_re, $project_re) };

            # Assemble output
            my %output = (
                'MUTATION_ID'   =>  $mutation{ID},
                'PROJ_AFFECTED_DONORS'  =>  (lc $project_str eq 'all') ? '' : $mutation{OCCURRENCE}->[0]->{affected_donors},
                'PROJ_TESTED_DONORS'    =>  (lc $project_str eq 'all') ? '' : $mutation{OCCURRENCE}->[0]->{tested_donors},
                'TOTAL_AFFECTED_DONORS' =>  $mutation{affected_donors},
                'TOTAL_TESTED_DONORS'   =>  $mutation{tested_donors}
            );

            # Output
			print_fields($output, \%output, \@output_line_fields);
		}
	}
}#===============>> END OF MAIN ROUTINE <<=====================

#	===========
#	Subroutines
#	===========

sub full_path
# Recieves a file name, returns the absolute path
# TODO: Needed better implementation.
{
	my $path = shift;

	if ( $path =~ '^/')
	{
		return $path;
	}
	else
	{
		return "$ENV{PWD}/$path";
	}
}
