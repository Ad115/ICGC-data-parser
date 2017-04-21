#! /usr/bin/perl

package GetRecurrenceData;
use Exporter qw'import';
	our @EXPORT = qw'get_recurrence_data';

#=====================================================================

our $doc_str = <<END;

Usage: $0 [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--offline] [--help]

==============================
 Get mutation recurrence data
==============================

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

	-f, --offline
		Work offline. i.e. don't connect to the Ensembl database.
		Requires the gene as stable ID or gene 'all'.

	-h, --help
		Show this text and exit.

Author: Andrés García García @ Oct 2016.

END


use ICGC_Data_Parser::SSM_Parser qw(:parse);
use ICGC_Data_Parser::Tools qw(:general_io :debug);

__PACKAGE__->main( @ARGV ) unless caller();

#===============>> BEGINNING OF MAIN ROUTINE <<=====================
sub main
{
	# Get class
	my $self = shift;
	
	parse_SSM_file(\@_,
		# Dispatch table
		{
			# Register output fields in context
			BEGIN	=>	sub { 
							$_[0]->{OUTPUT_FIELDS} = [qw(MUTATION_ID PROJ_AFFECTED_DONORS PROJ_TESTED_DONORS TOTAL_AFFECTED_DONORS TOTAL_TESTED_DONORS)];
						},
			   
			# Print header line
			START	=>	\&print_header,
			
			# Print the mutation recurrence data
			MATCH	=>	\&print_recurrence_data,
			
			# Print help and exit
			HELP	=>	sub { print_and_exit $doc_str }
		}
	);
}#===============>> END OF MAIN ROUTINE <<=====================


#	===========
#	Subroutines
#	===========


sub get_recurrence_data
{
	# Get arguments
	my %args = %{ shift() };

	# Parse the mutation data
	my %mutation = %{ parse_mutation(\%args) };

	# Assemble output
	return {
		'MUTATION_ID'   =>  $mutation{ID},
		'PROJ_AFFECTED_DONORS'  =>  ( specified( $args{project} ) )
									? $mutation{INFO}->{OCCURRENCE}->[0]->{affected_donors} : '',
		'PROJ_TESTED_DONORS'    =>  ( specified( $args{project} ) ) 
									? $mutation{INFO}->{OCCURRENCE}->[0]->{tested_donors} : '',
		'TOTAL_AFFECTED_DONORS' =>  $mutation{INFO}->{affected_donors},
		'TOTAL_TESTED_DONORS'   =>  $mutation{INFO}->{tested_donors}
	};
}#-----------------------------------------------------------

sub print_header
{
	my %context = %{ shift() }; # Get context (READ ONLY)
	
	# Get relevant context variables
	my ($project, $gene, $output, $output_fields) 
		= @context{qw(PROJECT GENE OUTPUT OUTPUT_FIELDS)};

	# Print heading lines
	print  $output "# Project: $project->{str}\tGene: $gene->{str}\n";
	print  $output join( "\t", @$output_fields)."\n";
}#-----------------------------------------------------------

sub print_recurrence_data
{
	my %cxt = %{ shift() }; # Get context (READ ONLY)
	
	# Get relevant context variables
	my ($output, $output_fields) 
		= @cxt{qw(OUTPUT OUTPUT_FIELDS)};
	
	# Get recurrence data
	my %output = %{ get_recurrence_data({
				line => $cxt{LINE},
				headers => $cxt{HEADERS},
				gene => $cxt{OPTIONS}->{gene},
				project => $cxt{OPTIONS}->{project},
				offline => $cxt{OPTIONS}->{offline}
			}
		)
	};

    # Output
	print_fields($output, \%output, $output_fields);
}#-----------------------------------------------------------

1; 