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
use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Data::Dumper; # To preety print hashes easily
	local $Data::Dumper::Purity = 1;
	local $Data::Dumper::Sortkeys = 1;

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
	my @output_line_fields = ('MUTATION_ID', 'POSITION', 'MUTATION', 'CONSEQUENCES', 'PROJ_AFFECTED_DONORS', 'TOTAL_AFFECTED_DONORS');

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


#	===========
#	Subroutines
#	===========

sub ensembldb_connect
# Initialize a connection to the db
{
  # Initialize a registry object
  my $registry = 'Bio::EnsEMBL::Registry';

  # Connect to the Ensembl database
  print STDERR "Waiting connection to database... ";
  $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
      -user => 'anonymous'
      );
  print STDERR "Connected to database\n";

  return $registry;
}#------------------------------------------------------

sub get_vcf_line
# Get a line from a VCF file
{
	my $vcffile = shift;

	# Skip comments
	my $line;
	do	{ $line = <$vcffile>; }
	while($line and $line =~ /^##.*/);

	# Check whether you are in the headers line
	if ($line and $line =~ /^#(.*)/) { $line = $1; }

	return $line;
}#-----------------------------------------------------------

sub get_vcf_fields
# Get a line from a VCF file splitted in fields
{
	my $vcffile = shift;

	# Skip comments
	my $line;
	do	{ $line = <$vcffile>; }
	while($line =~ /^##.*/);

	# Check wether you are in the headers line
	if ($line =~ /^#(.*)/) { $line = $1; }

	return split( /\t/, $line);
}#-----------------------------------------------------------

sub get_gene_id
# Query the database for the stable id of the given gene
{
  my $gene_name = shift;

  # Declare a gene adaptor to get the gene
  my $gene_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Gene' );
  # Declare a gene handler with the given gene
  my $gene = $gene_adaptor->fetch_by_display_label($gene_name);
  unless($gene) { die "ERROR: Gene '$gene_name' not found\n"; }

  # Get the gene's EnsembleStableID
  return $gene->stable_id();
}#-------------------------------------------------------

sub open_input
# Prints given message and opens input file
# Exit with error if it fails to open the file
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open input file
	print $message if $message;
	open ($file_handler, "<", $file_name)
		or die "Can't open $file_name for input : $!";
}#-----------------------------------------------------------

sub open_output
# Prints given message and opens file for output
# Exit with error if it fails to open the file
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open output file
	print $message;
	open ($file_handler, ">", $file_name)
		or die "Can't open $file_name for output : $!";
}#-----------------------------------------------------------

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
}#-----------------------------------------------------------

sub print_array
# Prints the content of the passed array
{
	my @array = @{shift()};
	my $name = shift;

	print "$name: (" . join(',', @array) . ")\n";
}#-----------------------------------------------------------

sub get_fields_from
# returns a dictionary with the positions of the fields
{
	my $inputfile = shift; # The input file
	my @fields = @_;	# The fields to search
		# If fields weren't specified, get all available ones
		@fields = get_vcf_fields($inputfile) unless (@_);

	# Get the column position of the searched fields
	my %fields = map {
					$_ => get_col_number($_, \@fields)
				} @fields;

	return %fields;
}#-----------------------------------------------------------

sub get_col_number
# Get the numeric position of the column whose name is given
{
	my $col_name = shift;
	my @fields = @{shift()};

	# Get the column numbers
	foreach my $i (0..$#fields)
	{
		return $i if ($col_name eq $fields[$i]);
	}

	die "Column '$col_name' not found!\n!";
}#-----------------------------------------------------------

sub print_fields
# USAGE: print_fields(\%hash, \@keys)
# Print orderly the values corresponding to the given keys of the hash
# Prints in TSV format
{
	my $output = shift;
	my %hash = %{shift()};
	my @keys = @{shift()};

	# Print the given fields
	foreach my $key (@keys)
	{
		print $output "$hash{$key}\t";
	}
	print "\n";
}#-----------------------------------------------------------

sub print_hash
# Prints the content of the passed hash
{
	my %hash = %{shift()};
	my $name = shift;

	print "$name: ".Dumper \%hash;
}#-----------------------------------------------------------

sub uniq
# Remove repeated entries from array
{
	my @array = @{shift()};

	my %seen;
	return grep !($seen{$_}++), @array;
}#-----------------------------------------------------------

sub get_affected_genes
# Get the affected genes for the mutation
{
	my $line = shift;

	my @genes = ($line =~ /(ENSG[0-9]+)/g);
	@genes = uniq(\@genes);
	foreach my $gene (@genes)
	{
		#Get common name if not provided
		my $display_label = get_display_label($gene);
		$gene = "$gene($display_label)";
	}

	return \@genes
}#-----------------------------------------------------------

sub get_display_label
# Get the display label for the genes in the gene array
{
	my $gene_id = shift;

	unless ($gene_name{$gene_id})
	{
		eval
		{
			$gene_name{$gene_id} = $connection
								-> get_adaptor( 'Human', 'Core', 'Gene' )
								-> fetch_by_stable_id($gene_id)
								-> external_name();

		}; if ($@)
		{
			warn $@;
			$gene_name{$gene_id} = 'NOLABEL';
		}
	}

	return $gene_name{$gene_id};
}#-----------------------------------------------------------

sub get_consequence_data
# Get the consequence data as a hash array from the mutation line
{
    my $line = shift;

    # Get the CONSEQUENCE field
    $line =~ /CONSEQUENCE=(.*?);/;

    # Split multiple consequences
    my @consequences
		= map {
                my @consequence=split /\|/, $_;
                {   'gene_symbol'	=>	$consequence[0],
					'gene_affected' =>  $consequence[1],
					'gene_strand' =>  $consequence[2],
					'transcript_name' =>  $consequence[3],
					'transcript_affected' =>  $consequence[4],
					'protein_affected' =>  $consequence[5],
                    'consequence_type'  => $consequence[6],
					'cds_mutation' =>  $consequence[7],
					'aa_mutation' =>  $consequence[8]
                };
			} split( /,/ , $1);

	return \@consequences;
}#-----------------------------------------------------------

sub get_occurrence_data
# Get the occurrence data as a hash array from the mutation line
{
	my $line = shift;

	# Get the OCCURRENCE field
	$line =~ /OCCURRENCE=(.*?);/;

	# Split multiple occurrences
    my @occurrences
		= map {
                my @occurrence = split /\|/, $_;
                {   'project_code'	=>	$occurrence[0],
					'affected_donors' =>  $occurrence[1],
					'tested_donors' =>  $occurrence[2],
					'frequency' =>  $occurrence[3]
                };
			} split( /,/ , $1);

    # Get global occurrence
	$line =~ /affected_donors=(.*?);.*project_count=(.*?);.*tested_donors=(.*?)$/;
	my %global_occurrence = (
		'project_code'	=>	'global',
		'affected_donors'	=>	$1,
		'project_count'	=>	$2,
		'tested_donors'	=>	$3
		);

	return (\%global_occurrence, \@occurrences);
}#-----------------------------------------------------------

sub dumper
# Returns the preety printed content of the given structure
{
	my $structure = shift;
	my $name = shift;

	return Data::Dumper->Dump([$structure], [$name]);
}#-----------------------------------------------------------

sub tweet
# Prints the content of the given structure
{
	my $structure = shift;
	my $name = shift;

	print dumper($structure, $name);
}#-----------------------------------------------------------

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

	return ($gene, $gene_id, $gene_str, $gene_re);
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
			'CONSEQUENCES'	=>	$consequences,
			'PROJ_AFFECTED_DONORS'	=>	$occurrences,
			'TOTAL_AFFECTED_DONORS'	=>	$global_occurrence
			);

	return %mutation;
}#-----------------------------------------------------------
