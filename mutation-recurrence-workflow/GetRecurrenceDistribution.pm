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
use ICGC_Data_Parser::Tools qw(:general_io);

use Getopt::Long qw(:config bundling); # To parse command-line arguments

__PACKAGE__->main( @ARGV ) unless caller();
#===============>> BEGINNING OF MAIN ROUTINE <<=====================
sub main
{
## INITIALIZATION
	# Get class
	my $self = shift;
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
    if( $opt{help} ) { print_and_exit($doc_str); }

## MAIN QUERY

	my %distribution = %{ 
		$self -> get_reccurrence_distribution({
				input => $input,
				gene => $opt{gene},
				project => $opt{project},
				offline => $opt{offline}
			}
		)
	};
	my $tested_donors = $distribution{TESTED_DONORS};
	delete $distribution{TESTED_DONORS};

## OUTPUT

	# Get project's data
	my $project_str = (specified $opt{project}) ? $opt{project} : "All";
	
	# Get gene's data
	my $gene_str 
		= get_gene_data($opt{gene}, $opt{offline})
					->{str};

	# Assemble output fields
	my @output_line_fields = qw(MUTATIONS AFFECTED_DONORS_PER_MUTATION);
	my %output = ();

	# Print heading lines
	print  $output "# Project: $project_str\tGene: $gene_str\tTested donors: $tested_donors\n";
	print  $output join( "\t", @output_line_fields)."\n";

	foreach my $key (sort {$a <=> $b} keys %distribution){
		# Assemble output
		$output{AFFECTED_DONORS_PER_MUTATION} = $key;
		$output{MUTATIONS} = $distribution{$key};

		print_fields($output, \%output, \@output_line_fields);
	}

}#===============>> END OF MAIN ROUTINE <<=====================

#	===========
#	Subroutines
#	===========

sub get_reccurrence_distribution
{
	# Get arguments
	my $self = shift;
	my %args = %{ shift() };
	# $input, $gene, $project

	# Get header fields
	my $headers = get_vcf_headers($args{input});
	
	# Get regular expressions for the gene and project
	my %regexp = %{ get_query_re( {
				project	=>	$args{project},
				gene	=>	$args{gene}
			},
			$args{offline}
		)
	};
	
	#Initialize distribution
	my %distribution = ();
	
	while(my $line = get_vcf_line($args{input})) # Get mutation by mutation
	{
		# Check for specified gene and project
		if ($line =~ $regexp{gene} and $line =~ $regexp{project})
		{
            # Parse the mutation data
			my %mutation = %{ parse_mutation({
						line	=>	$line,
						headers	=>	$headers,
						gene	=>	$args{gene},
						project	=>	$args{project},
						offline	=>	$args{offline}
					}
				)
			};

			# Associate AFFECTED_DONORS : MUTATIONS
			if (specified $args{project}){
				# When a project is specified
				$distribution{ $mutation{INFO}->{OCCURRENCE}->[0]->{affected_donors} }++;
				$distribution{ TESTED_DONORS } = $mutation{INFO}->{OCCURRENCE}->[0]->{tested_donors};
			} else{
				# When all projects are parsed
				$distribution{ $mutation{INFO}->{affected_donors} }++;
				$distribution{ TESTED_DONORS } = $mutation{INFO}->{tested_donors};
			}
		}
	}
	return \%distribution;
}#-----------------------------------------------------------

1;