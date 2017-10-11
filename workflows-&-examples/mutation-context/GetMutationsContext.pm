#! /usr/bin/perl

package GetMutationContext;
use Exporter qw'import';
	our @EXPORT_OK = qw'get_mutation_context print_header';

#=====================================================================

our $doc_str = <<END;

Usage: $0 [--in=<file>] [--out=<outfile>] [--help]

============================
 Locate mutations in genome
============================

Queries the Ensembl database about the genomic context of each mutation in the input.
The input is a VCF file in the format of the ICGC SSM file.
The program assigns each mutation with one of the next labels: 
INTERGENIC, EXONIC:#, NON-CODING-EXONIC, INTRONIC. Where the '#' stands for
the *phase* understood as the position in the codon, and can be 0, 1 or 2.

Command-line arguments:

	-i, --in
		Name of the input file.
		If not present, input from standard input.

	-o, --out
		Name of the output file.
		If not present output to standard output.

	-h, --help
		Show this text and exit.

Author: Andrés García García @ Dic 2016.

END


use ICGC_Data_Parser::Ensembl qw(:genome);
use ICGC_Data_Parser::SSM_Parser qw(:parse);
use ICGC_Data_Parser::Tools qw(:general_io uniq :debug);

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
            RAW_OPTIONS =>  \@_,
            
            # Format strings for the expected command-line options (other than in, out and help)
            EXPECTED_OPTIONS   =>  [ 'chrom|c=s' ],
        },
        
		# Table of actions
		{
            # Do this just before parsing the file
			START	=>	sub { 
							my $context = shift; # Get context
							
							# Register output fields in context
							$context->{OUTPUT_FIELDS} = [qw(MUTATION_ID MUTATION POSITION_GRCh37 POSITION_GRCh38 RELATIVE_POSITION OVERLAPPED_GENES CONSEQUENCE(S) PROJECT(S))];
							
							# Print header line
							print_header($context);
						},
			
			# Print the mutation recurrence data
			MATCH	=>	\&print_context_data,
			
			# Print help and exit
			HELP	=>	sub { print_and_exit $doc_str }
		}
	);
}#===============>> END OF MAIN ROUTINE <<=====================


#	===========
#	Subroutines
#	===========


sub get_mutation_context
{
	# Get the mutation data
	my %mutation = %{ shift() };
	#tweet \%mutation;

	# Assemble output
	my $pos_GRCh38 = map_GRCh37_to_GRCh38( $mutation{'CHROM'}, $mutation{'POS'}, 1 )->[0];
	
	my $projects = join( ',', 
						 map { $_->{project_code} } @{ $mutation{INFO}->{OCCURRENCE} } 
					);
	
	my $consequences = join( ',', 
							uniq
								map { "$_->{gene_affected}($_->{gene_symbol}):$_->{consequence_type}" } 
									grep { $_ -> {gene_affected} }
										@{ $mutation{INFO}->{CONSEQUENCE} } 
						);
	
	my $slice = fetch_slice($mutation{CHROM}, $pos_GRCh38, 1);
	my $overlapping = $slice -> get_all_Genes();
	
	my $overlapped_genes = join( ',', 
								 map {	get_Gene_print_data($_) }
									@{ $overlapping }
							);

	my $relative_position = get_gene_context({SLICE => $slice, OVERLAPPING_GENES => $overlapping});
	
	return {
		MUTATION_ID	=>	$mutation{ID},
		MUTATION	=>	$mutation{INFO}->{mutation},
		POSITION_GRCh37	=>	"chr$mutation{CHROM}:$mutation{POS}",
		POSITION_GRCh38	=>	"chr$mutation{CHROM}:$pos_GRCh38",
		RELATIVE_POSITION	=>	$relative_position,
		OVERLAPPED_GENES	=>	$overlapped_genes,
		'CONSEQUENCE(S)'	=>	$consequences,
		'PROJECT(S)'	=>	$projects
	};
}#-----------------------------------------------------------

sub print_header
{
	my %context = %{ shift() }; # Get context (READ ONLY)
	
	# Get relevant context variables
	my ($project, $gene, $output, $output_fields) 
		= @context{qw(PROJECT GENE OUTPUT OUTPUT_FIELDS)};
		
    my $chrom = $context{OPTIONS}{chrom};
    $chrom = 'All' unless $chrom;

	# Print heading lines
	print  $output "# Project: $project->{str}\tGene: $gene->{str}\tChromosome: $chrom\n";
	print  $output join( "\t", @$output_fields)."\n";
}#-----------------------------------------------------------

sub print_context_data
{
	my %cxt = %{ shift() }; # Get context (READ ONLY)
	
	# Get relevant context variables
	my ($output, $output_fields) 
		= @cxt{qw(OUTPUT OUTPUT_FIELDS)};
	
	my $mutation = parse_mutation({
				line => $cxt{LINE},
				headers => $cxt{HEADERS},
				gene => $cxt{OPTIONS}->{gene},
				project => $cxt{OPTIONS}->{project},
				offline => $cxt{OPTIONS}->{offline}
            }
        );
	
	my $chrom = $cxt{OPTIONS}{chrom};
	
	if ($chrom eq $mutation->{CHROM}) {
	# Filter by chromosome
	
        # Get context data
        my $context_data = get_mutation_context($mutation);

        # Output
        print_fields($output, $context_data, $output_fields);
    }
}#-----------------------------------------------------------

1; 
