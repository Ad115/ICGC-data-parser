#! /usr/bin/perl

use strict;
use warnings;

my $doc_str = <<END;

Usage: filter_gene_project.pl [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--help]

============================
 Filter by gene and project
============================

Searches through input file for mutations related to the given gene and the given project.
Prints important data of each in tsv format.

Common genes: TP53(ENSG00000141510), ERBB2(HER2)(ENSG00000141736), MDM2(ENSG00000135679), BRCA1(ENSG00000012048), ATM(ENSG00000149311), CDK2(ENSG00000123374).
Common projects: BRCA-EU, GBM-US.

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


use Getopt::Long; # To parse command-line arguments

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Hash to store option values
	my %opts = ();
	# Parse command line options into the options(o) hash
	GetOptions(\%opts,
		'in|i||vcf=s',
		'out|o=s',
		'gene|g=s',
		'project|p=s',
		'help|h'
		);


	my $input = *STDIN;# Open input file
	if( $opts{in} )  { open_input($input, $opts{in}); }


	my $output = *STDOUT; # Open output file
	if ( $opts{out} )  { open_output($output, $opts{out}); }

	# Check if user asked for help
	if( $opts{help} ) { print_and_exit($doc_str); }


## LOCAL DATA INITIALIZATION

	# Get fields
	my %fields = get_fields_from($input);

## WEB DATA INITIALIZATION

	# Initialize a connection to the db.
	our $connection = ensembldb_connect();

	our %gene_name = (); # To store an association of gene's stable_id -> display_label

	# Get gene's data
	my ($gene, $gene_id, $gene_str, $gene_re) = get_gene_query_data($opts{gene});
	# Get project's data
	my ($project_str, $project_re) = get_project_query_data($opts{project});

	# Assemble output fields
	my @output_line_fields = ('MUTATION_ID', 'POSITION', 'MUTATION', 'PROJ_AFFECTED_DONORS', 'TOTAL_AFFECTED_DONORS', 'CONSEQUENCES');

	# Print heading lines
	print $output "# Project: $project_str\tGene: $gene_str\n";
	print $output join( "\t", @output_line_fields)."\n";

## MAIN QUERY

	while(my $line = get_vcf_line($input)) # Get mutation by mutation
	{
		# Check for specified gene and project
		if ($line =~ $gene_re and $line =~ $project_re)
		{
			my %mutation = parse_mutation($line, \%fields);
			print_fields($output, \%mutation, \@output_line_fields);
		}
	}


#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


sub path
# Recieves a file path, returns the absolute path
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









sub get_gene_query_data
# Get the relevant data for the given gene (given display label or stable ID)
{
	my $gene = shift; # may be display label or stable id

	my $gene_id = undef;
	if ($gene)
	{
		if ($gene =~ /ENSG[0-9.]*/) # User provided stable ID
		{
			$gene_id = $gene;
			# Get common name
			$gene = get_display_label($gene_id);
		}
		elsif (lc $gene eq 'all') # User wants to search in all genes
		{
			$gene = '';
		}
		else # User provided the display label
		{
			$gene_id = get_gene_id($gene);
			$gene_name{$gene_id} = $gene;
		}
	}

	my $gene_str = ($gene) ? "$gene_name{$gene_id}($gene_id)" : "All";
	my $gene_re = ($gene_id) ? qr/$gene_id/ : qr/.*/;

	return [$gene, $gene_id, $gene_str, $gene_re];
}#-----------------------------------------------------------

sub get_project_query_data
# Get the relevant data for the given project
{
	my $project = shift;

	# Stringify project
	my $project_str = ($project) ? $opts{project} : "All";
	# Compile a REGEX with the project name
	my $project_re = ($opts{project}) ? qr/$opts{project}/ : qr/.*/;

	return ($project_str, $project_re);
}#-----------------------------------------------------------

sub split_in_fields
# Get a hash with the line decomposed in fields
{
	my %fields = %{ shift() };
	my @line = split( /\t/, shift() );

	return map { $_ => $line[$fields{$_}] } keys %fields;
}#-----------------------------------------------------------

sub get_consequence_string
# Get a string with the consequence data for the mutation
{
	my $line = shift;

	my @consequences = map {
		my $string = $_->{consequence_type};
		my $gene = $_->{gene_affected};
		$string .= ($gene) ? "\@$gene(".get_display_label($gene).")" : '';
		$string;
	} @{get_consequence_data($line)};

	return join( ',', uniq(\@consequences) );
}#-----------------------------------------------------------

sub get_occurrence_strings
# Get a string with the consequence data for the mutation
{
	my $line = shift;

	# Get occurrence data
	my ($global, $occurrences) = get_occurrence_data($line);

	# Occurrences in each project
	my @occurrences = map {
		"$_->{project_code}($_->{affected_donors}/$_->{tested_donors})"
	} @{ $occurrences };

	# Global occurrence of the mutation
	my $global_occurrence = "$global->{affected_donors}/$global->{tested_donors}($global->{project_count} projects)";

	return ( join( ',', @occurrences ),
			 $global_occurrence
		);
}#-----------------------------------------------------------

sub parse_mutation
# Get a hash with the mutation data to print
{
	my $line = shift;
	my $fields = shift;

	# Split line in fields
	my %line = split_in_fields($fields, $line);

	#Get consequence data
	my $consequences = get_consequence_string($line);

	# Get occurrence data
	my ($occurrences, $global_occurrence) = get_occurrence_strings($line);

	my %mutation = (
			'MUTATION_ID'	=>	$line{ID},
			'POSITION'	=>	"Chrom$line{CHROM}($line{POS})",
			'MUTATION'	=>	"$line{REF}>$line{ALT}",
			'TOTAL_AFFECTED_DONORS'	=>	$global_occurrence,
            'PROJ_AFFECTED_DONORS'	=>	$occurrences,
            'CONSEQUENCES'	=>	$consequences
			);

	return %mutation;
}#-----------------------------------------------------------
