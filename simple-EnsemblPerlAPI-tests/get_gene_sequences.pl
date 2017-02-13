#! /usr/bin/env perl

my $doc_str = <<END;

Usage: get_gene_sequences.pl --genes=<gene1>,<gene2>,... [--length=<l>] [--help]

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

	-l --length
		A number that specifies the maximum length of the obtained sequences
		Default is to get all the sequence.

	-h, --help
		Show this text and exit.

Example call: get_gene_sequences.pl -g TP53,ENSG00000141736,MDM2,ENSG00000012048,ATM,ENSG00000123374 -l 100
		
Author: Andrés García García @ May 2016.

END

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Getopt::Long; # To parse command-line arguments

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION
	my $genes = ''; my $length = 0;
	my $help;
	GetOptions(
		'g|gene|genes=s' => \$genes,
		'l|length=i' => \$length,
		'h|help' => \$help
		);
	
	# Check if user asked for help
	if($help || !$genes) { print_and_exit($doc_str); }
	
	my @genes = split( ',', $genes );

## WEB INITIALIZATION
	# Initialize a connection to the db.
	my $connection = ensembldb_connect();
	my $slice_adaptor = $connection -> get_adaptor('Human', 'Core', 'Slice'); # Declare a slicer to get the sequences
	my $gene_adaptor = $connection -> get_adaptor( 'Human', 'Core', 'Gene' ); # Declare a gene adaptor to get the gene ids

## MAIN LOOP
	foreach my $gene (@genes)
	{
		# Get display label and stable ID
		my $gene_id = '';
		if ($gene =~ /ENSG[0-9]{11}/) # User provided stable ID
		{
			$gene_id = $gene;
			# Get common name
			$gene = get_display_label($gene_id);
		}
		else # User provided the display label
		{ 
			$gene_id = get_gene_id($gene); 
		}
		
		print "==> Gene: $gene($gene_id) <==\n";

		# Query for the sequence
		my $sequence = '';
		$sequence = get_sequence($gene_id, $length) if ($gene_id);
		print "Sequence: $sequence \n";
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
  print STDERR "Waiting connection to database...\n";
  
	$registry->load_registry_from_db(
		-host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
		-user => 'anonymous'
		);
	
  print STDERR "...Connected to database\n";
 
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
		$sequence = ($length) ? $slice->subseq(1, $length) : $slice->seq();
		
	}; if ($@) { warn $@; }
  
  return $sequence;
} #------------------------------------------------------
