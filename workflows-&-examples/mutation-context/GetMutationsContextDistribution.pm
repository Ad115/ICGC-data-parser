#! /usr/bin/perl

package GetMutationContextDistribution;
use lib '.';
	use GetMutationContext qw(get_mutation_context print_header);
use Exporter qw'import';
	our @EXPORT = qw'';

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
		# Dispatch table
		{	# Collect the mutation recurrence data
			MATCH	=>	\&assemble_context_distribution,
			
			# Print the resulting data
			END	=>	\&print_context_distribution,
			
			# Print help and exit
			HELP	=>	sub { print_and_exit $doc_str }
		}
	);
}#===============>> END OF MAIN ROUTINE <<=====================


#	===========
#	Subroutines
#	===========

sub assemble_context_distribution
{
	my $cxt = shift(); # Get context (READ/WRITE)
	
	# Create a distribution if not created yet
	$cxt->{DISTRIBUTION} //= {};
	
	# Get relevant context variables
	my $distribution = $cxt->{DISTRIBUTION};
	
	my %opts = %{ $cxt->{OPTIONS} };
	
	# Parse mutation
	my $mutation = parse_mutation({
				line => $cxt{LINE},
				headers => $cxt{HEADERS},
				gene => $cxt{OPTIONS}->{gene},
				project => $cxt{OPTIONS}->{project},
				offline => $cxt{OPTIONS}->{offline}
            }
        );

    my $chrom = $cxt{OPTIONS}{chrom};
	
	if (!$chrom or ($chrom eq $mutation->{CHROM})) {
	# Filter by chromosome
	
        # Get context data
        my $context_data = get_mutation_context($mutation);
	
        # Assemble distribution
        my $relative_position = $context_data{RELATIVE_POSITION};
        $distribution->{$relative_position}++;
    }
}#-----------------------------------------------------------


sub print_context_distribution
{
	my %context = %{ shift() }; # Get context (READ ONLY)
	
	# Get relevant context variables
	my ($distribution, $output) = @context{qw'DISTRIBUTION OUTPUT'};
	
	## OUTPUT

	# Assemble output fields
	$context{OUTPUT_FIELDS} = [qw(RELATIVE_POSITION RELATIVE_POSITION_COUNT)];
	print_header(\%context);

	my %output = ();
	foreach my $key (sort {$a <=> $b} keys %$distribution){
		# Assemble output
		$output{RELATIVE_POSITION} = $key;
		$output{RELATIVE_POSITION_COUNT} = $distribution->{$key};
		print_fields($output, \%output, $context{OUTPUT_FIELDS});

	}

}#-----------------------------------------------------------

1; 
