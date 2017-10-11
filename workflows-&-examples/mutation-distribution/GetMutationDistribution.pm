#! /usr/bin/perl

package GetMutationDistribution;
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
	
	parse_SSM_file(\@_,
		# Dispatch table
		{
			# If asked for help
			HELP	=>	sub { print_and_exit $doc_str },
			
			# Asemmble distribution at matching line
			MATCH	=>	\&assemble_mutation_distribution,
			
			# Print distribution at the end
			END	=>	\&print_mutation_distribution
		}
	);
}#===============>> END OF MAIN ROUTINE <<=====================


#	===========
#	Subroutines
#	===========

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

sub assemble_mutation_distribution
{
	my $cxt = shift(); # Get context (READ/WRITE)
	
	# Create a distribution if not created yet
	$cxt->{DISTRIBUTION} //= {};
	
	# Get relevant context variables
	my $distribution = $cxt->{DISTRIBUTION};
	
	my %opts = %{ $cxt->{OPTIONS} };
	
	# Associate GENE_ID:mutations_found in gene
	my @gene_ids = $cxt->{LINE} =~ /(ENSG[0-9.]*)/;
	
	map { $distribution->{$_}++ } @gene_ids;
}#-----------------------------------------------------------

sub print_mutation_distribution
{
	my %context = %{ shift() }; # Get context (READ ONLY)
	
	# Get relevant context variables
	my ($output, $distribution) 
		= @context{qw(OUTPUT DISTRIBUTION)};

	## OUTPUT

	# Assemble output fields
	$context{OUTPUT_FIELDS} = [qw(MUTATIONS_COUNT GENE_COUNT GENES)];
	print_header(\%context);

	# Arrange distribution
	my %mutation_frequency = ();
	foreach my $gene_id (keys %$distribution){
		
		# Assemble gene mutation frequency distribution
		$mutation_frequency{$distribution->{$gene_id}}->{GENE_COUNT}++;
		
		# Append ID to the gene id's found
		if (defined $mutation_frequency{$distribution->{$gene_id}}->{GENES}){
			$mutation_frequency{$distribution->{$gene_id}}->{GENES} .= ",$gene_id";
		} else {
			$mutation_frequency{$distribution->{$gene_id}}->{GENES} = $gene_id;
		}
	}
	
	# Print output
	foreach my $key (sort {$a <=> $b} keys %mutation_frequency){
		# Assemble output
		$output{MUTATIONS_COUNT} = $key;
		$output{GENES} = $mutation_frequency{$key}->{GENES};
		$output{GENE_COUNT} = $mutation_frequency{$key}->{GENE_COUNT};

		print_fields($output, \%output, $context{OUTPUT_FIELDS});
	}

}#-----------------------------------------------------------

1; 
