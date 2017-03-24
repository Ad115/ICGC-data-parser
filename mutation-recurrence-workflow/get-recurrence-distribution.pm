#! /usr/bin/perl

package GetRecurrenceDistribution;
use Exporter qw'import';
	our @EXPORT = qw'main';

#=====================================================================

our $doc_str = <<END;

Usage: $0 [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--offline] [--help]

=======================================
 Get mutation reccurrence distribution
=======================================

Searches through input file for mutations related to the given gene and the given project.
Gets the mutation recurrence distribution for the data (i.e. how many mutations are repeated in ``n`` different patients in a given cancer project and a given gene?)

	-g, --gene
		Gene name, in display form or as stable ID.
		If present, analyzes only mutations that affect the gene.
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

	-f, --offline
		Work offline. i.e. don't connect to the Ensembl database.
		Requires the gene as stable ID or gene 'all'.

	-h, --help
		Show this text and exit.

Author: Andrés García García @ Oct 2016.

END

use lib '../lib';
    use ICGC_Data_Parser::SSM_Parser qw(:parse);
    use ICGC_Data_Parser::Tools qw(:general_io);

use Getopt::Long qw(:config bundling); # To parse command-line arguments

main(@ARGV) unless caller();
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
		'offline|f',
        'help|h'
        );


    my $input = *STDIN;# Open input file
    if( $opt{in} )  { open_input( $input, full_path($opt{in}) ); }


    my $output = *STDOUT; # Open output file
    if( $opt{out} )  { open_output( $output, full_path($opt{out}) ); }

    # Check if user asked for help
    if( $opt{help} ) { print $doc_str; print_and_exit($doc_str); }

## LOCAL DATA INITIALIZATION

	# Get fields
	my %fields = parse_fields($input);

	# Get project's data
	my ($project_str, $project_re) = @{ get_project_data($opt{project}) };

## WEB DATA INITIALIZATION

	# Get gene's data
	my ($gene_str, $gene_re) = @{ get_gene_data($opt{gene}, $opt{offline}) };

	# Initialize counter
	my %count = ();
	my %output = ();

## MAIN QUERY

	while(my $line = get_vcf_line($input)) # Get mutation by mutation
	{
		# Check for specified gene and project
		if ($line =~ $gene_re and $line =~ $project_re){
            # Parse the mutation data
			my %mutation = %{ parse_mutation($line, \%fields, $gene_re, $project_re) };

			# Associate AFFECTED_DONORS : MUTATIONS
			if (lc $project_str eq 'all'){
				# When all projects are parsed
				$count{ $mutation{INFO}->{affected_donors} }++;
				$output{TESTED_DONORS} = $mutation{INFO}->{tested_donors};
			} else{
				# When a project is specified
				$count{ $mutation{INFO}->{OCCURRENCE}->[0]->{affected_donors} }++;
				$output{TESTED_DONORS} = $mutation{INFO}->{OCCURRENCE}->[0]->{tested_donors};
			}
		}
	}

## OUTPUT

	# Assemble output fields
	my @output_line_fields = qw(MUTATIONS AFFECTED_DONORS_PER_MUTATION);

	# Print heading lines
	print  $output "# Project: $project_str\tGene: $gene_str\tTested donors: $output{TESTED_DONORS}\n";
	print  $output join( "\t", @output_line_fields)."\n";

	foreach my $key (sort {$a <=> $b} keys %count){
		# Assemble output
		$output{AFFECTED_DONORS_PER_MUTATION} = $key;
		$output{MUTATIONS} = $count{$key};

		print_fields($output, \%output, \@output_line_fields);
	}

}#===============>> END OF MAIN ROUTINE <<=====================

#	===========
#	Subroutines
#	===========
