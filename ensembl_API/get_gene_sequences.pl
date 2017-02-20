#! /usr/bin/env perl

my $doc_str = <<END;

Usage: $0 --genes=<gene1>,<gene2>,... [--length=<l>] [--help]

=======================
Gene secuence obtainer.
=======================

Script to get the nucleotide sequence of a list of genes.
The sequences are obtained from the Ensembl database.
Requires BioPerl and the Ensembl Perl API library installed to work.
Installation instructions are in
[REQUIREMENTS_INSTALL_README.md](https://github.com/Ad115/ICGC-data-parser/blob/develop/REQUIREMENTS_INSTALL_README.md).

Command-line arguments:

	-g, --gene, --genes
		Genes to query.
		A comma separated list of genes in display form or as stable ID.

	-l --length (optional)
		A number that specifies the maximum length of the obtained sequences
		Default is 100, value 'all' gets the entire sequence.

	-s --species (optional)
		Specifies a species to look in.
		Defaults to 'Homo sapiens'.

	-S --list-species (optional)
		Lists available species to query data from and exits.

	-h, --help
		Show this text and exit.

Example calls:
	$0 -g TP53,ENSG00000141736 -l200
	$0 -g BRCA1 -s 'Homo sapiens'
	$0 -g Cntnap1 -s mouse
	$0 -g kif6 -s danio_rerio

Author: Andrés García García @ May 2016.

END

use 5.010; use strict; use warnings; # To have a clean code
use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Getopt::Long qw(:config bundling); # To parse command-line arguments
$" = ", "; # Default list separator

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION
	my $genes = ''; my $length = '100';
	my $species = 'Homo sapiens';
	my $list_species; my $help;
	GetOptions(
		'g|gene|genes=s' => \$genes,
		'l|length=s' => \$length,
		's|species=s' => \$species,
		'S|list-species' => \$list_species,
		'h|help' => \$help
		);

	# Check if user asked for help
	if($help || !($genes||$list_species) ) { print_and_exit($doc_str); }

	my @genes = split( ',', $genes );

## WEB INITIALIZATION
	# Initialize a connection to the db.
	my $connection = ensembldb_connect();

	# Check if user asked for the available species
    if( $list_species )
    {
		my @species = get_available_species();
        print_and_exit( "Available species: @species\n" );
    }

	# Get the adaptors for getting genes and slices
	my $slice_adaptor = $connection -> get_adaptor( $species, 'Core', 'Slice' ); # Declare a slicer to get the sequences
	my $gene_adaptor = $connection -> get_adaptor( $species, 'Core', 'Gene' ); # Declare a gene adaptor to get the gene ids

## MAIN LOOP
	foreach my $gene (@genes)
	{
		# Get display label and stable ID
		my $gene_id = '';
		if ($gene =~ /ENS[A-Z]*[0-9.]*/) # User provided stable ID
		{
			$gene_id = $gene;
			# Get common name
			$gene = get_display_label($gene_id);
		}
		else # User provided the display label
		{
			$gene_id = get_gene_id($gene);
		}

		# Get gene position
		my $position = get_position($gene_id);

		# Query for the sequence
		my $sequence = '';
		$sequence = get_sequence($gene_id, $length) if ($gene_id);

		print <<END;
<===============================================================================>
Gene: $gene($gene_id) in $species
Position: $position
Sequence: $sequence
<===============================================================================>

END
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

  print STDERR "Connected to database!\n";

  return $registry;
}#------------------------------------------------------

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
}#-----------------------------------------------------------

sub get_gene_id
# Query the database for the stable id of the given gene
{
  my $gene_name = shift;

  my $stable_id = undef;
  eval
	{
		# Get stable_id
		$stable_id = $gene_adaptor
						-> fetch_by_display_label($gene_name)
						-> stable_id();
	}; if ($@)
	{ warn $@; }

  # Get the gene's EnsembleStableID
  return $stable_id;
}#-------------------------------------------------------

sub get_display_label
# Get the display label for the genes in the gene array
{
	my $gene_id = shift;

	my $gene_name = '';
	eval
	{
		$gene_name = $gene_adaptor
						-> fetch_by_stable_id($gene_id)
						-> external_name();
	}; if ($@) { warn $@; }

	return $gene_name;
} #-------------------------------------------------------

sub get_sequence
# From the stable id of a gene, query the db for the nucleotide sequence
{
  my $gene_id = shift; # Get the gene ID
  my $length = shift; # Get the length to obtain

  my $sequence = '';
  eval
	{
		# Point a slice to where the gene is located, using the gene's ID
		my $slice = $slice_adaptor
						-> fetch_by_gene_stable_id($gene_id);
		# Get sequence
		$sequence = (lc $length eq 'all') ? $slice->seq() : $slice->subseq(1, $length);

	}; if ($@) { warn $@; }

  return $sequence;
} #------------------------------------------------------

sub get_position
# From the stable id of a gene, query the db for the chromosome and position in chromosome
{
  my $gene_id = shift; # Get the gene ID

  my $position = '';
  eval
	{
		# Point a slice to where the gene is located, using the gene's ID
		my $slice = $slice_adaptor
						-> fetch_by_gene_stable_id($gene_id);
		# Assemble the position text
		$position = "Chromosome ".$slice->seq_region_name().' '.$slice->start().'-'.$slice->end();

	}; if ($@) { warn $@; }

  return $position;
} #------------------------------------------------------

sub get_available_species
# Returns a list of the available species to query in the Ensembl database
{
    my @db_adaptors = @{ $connection->get_all_DBAdaptors() };

    # Assemble the species array
    my @species = map {$_->species()}
					grep {lc $_->group() eq 'core'}
						@db_adaptors;

    return @species;
}#-----------------------------------------------------------
