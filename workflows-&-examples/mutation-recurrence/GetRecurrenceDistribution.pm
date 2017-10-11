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

use ICGC_Data_Parser::SSM_Parser qw(:parse);
use ICGC_Data_Parser::Tools qw(:general_io :debug);

__PACKAGE__->main( @ARGV ) unless caller();
#===============>> BEGINNING OF MAIN ROUTINE <<=====================
sub main
{
	# Get class
	my $self = shift;
	
	parse_SSM_file(
		# Context data
        {   
            # Raw command-line options
            RAW_OPTIONS =>  \@_
        },
        
		# Table of actions
		{
			# If asked for help
			HELP	=>	sub { print_and_exit $doc_str },
			
			# Asemmble distribution at matching line
			MATCH	=>	\&assemble_recurrence_distribution,
			
			# Print distribution at the end
			END	=>	\&print_recurrence_distribution
		}
	);
}#===============>> END OF MAIN ROUTINE <<=====================


#	===========
#	Subroutines
#	===========

sub assemble_recurrence_distribution
{
	my $cxt = shift(); # Get context (READ/WRITE)
	
	# Create a distribution if not created yet
	$cxt->{DISTRIBUTION} //= {};
	
	# Get relevant context variables
	my $distribution = $cxt->{DISTRIBUTION};
	
	my %opts = %{ $cxt->{OPTIONS} };
	
	my %mutation = %{ parse_mutation({
				line => $cxt->{LINE},
				headers => $cxt->{HEADERS},
				gene => $opts{gene},
				project => $opts{project},
				offline => $opts{offline}
			}
		)
	};
	
	# Associate AFFECTED_DONORS : MUTATIONS
	if (specified $opts{project}){
		# When a project is specified
		$distribution->{ $mutation{INFO}->{OCCURRENCE}->[0]->{affected_donors} }++;
		$cxt->{ TESTED_DONORS } = $mutation{INFO}->{OCCURRENCE}->[0]->{tested_donors};
	} else{
		# When all projects are parsed
		$distribution->{ $mutation{INFO}->{affected_donors} }++;
		$cxt->{ TESTED_DONORS } = $mutation{INFO}->{tested_donors};
	}
}

sub print_recurrence_distribution
{
	my %context = %{ shift() }; # Get context (READ ONLY)
	
	# Get relevant context variables
	my ($output, $distribution, $tested_donors) 
		= @context{qw(OUTPUT DISTRIBUTION TESTED_DONORS)};
	
	my $project_str = $context{PROJECT}->{str};
	my $gene_str = $context{GENE}->{str};

	## OUTPUT

	# Assemble output fields
	my @output_line_fields = qw(MUTATIONS AFFECTED_DONORS_PER_MUTATION);

	# Print heading lines
	print  $output "# Project: $project_str\tGene: $gene_str\tTested donors: $tested_donors\n";
	print  $output join( "\t", @output_line_fields)."\n";

	my %output = ();
	foreach my $key (sort {$a <=> $b} keys %$distribution){
		# Assemble output
		$output{AFFECTED_DONORS_PER_MUTATION} = $key;
		$output{MUTATIONS} = $distribution->{$key};

		print_fields($output, \%output, \@output_line_fields);
	}

}

1; 
