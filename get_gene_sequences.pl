#! /usr/bin/env perl
=begin
=======================
Gene secuence obtainer.
=======================

Script to get the nucleotide sequence of a list of genes.
The sequences are obtained from the Ensembl database.
Requires BioPerl and the Ensembl Perl API library installed to work.
Installation instructions are in the SEQUENCES_README.md file or 
in https://github.com/Ad115/ICGC-data-parser/blob/develop/SEQUENCES_README.md
=cut

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.


#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Initialize a connection to the db.
my $connection = ensembldb_connect();

# Get list of genes
my @genes = array_input("Input genes to query...\n");

foreach my $gene_name (@genes)
{
    print "GENE\t $gene_name \n";

    # Query for the sequence
    my $sequence = get_sequence_from_name($gene_name); # As a side effect it prints the gene id
    print "$sequence \n";
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
  $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
      -user => 'anonymous'
      );
  return $registry;
}#------------------------------------------------------

sub array_input
# Gets input from user as scalars separated by comma, space or tabs,
# Prints input message if provided
# Returns an array with the input values
{
  my $prompt = shift;
	my $input;

  print $prompt; # Prompt user for input.
	chomp($input = <>); # Get input as string, remove trailing newlines
	# Separate into values
	my @input = split(/[, \t]+/, $input);
	return @input;
}#------------------------------------------------------

sub get_sequence_from_name
# Given the common name of the gene (as given by ICGC), get it's sequence.
{
  my $gene_name = shift; # Get the passed argument

  # Get the gene's stable id
  my $gene_id = get_geneid($gene_name);
  print "GENE_ID\t $gene_id \n";
  # Get the gene's sequence from the id
  my $sequence = get_sequence_from_id($gene_id);

  return $sequence;
}

sub get_geneid
# Query the database for the stable id of the given gene
{
  my $gene_name = shift;

  # Declare a gene adaptor to get the gene
  my $gene_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Gene' );
  # Declare a gene handler with the given gene
  my $gene = $gene_adaptor->fetch_by_display_label($gene_name);

  # Get the gene's EnsembleStableID
  return $gene->stable_id();
}#------------------------------------------------------

sub get_sequence_from_id
# From the stable id of a gene, query the db for the nucleotide sequence
{
  my $gene_id = shift; # Get the passed argument

  # Declare a slicer to get the sequence
  my $slice_adaptor
      = $connection -> get_adaptor('Human', 'Core', 'Slice');
  # Point a slice to where the gene is located, using the gene's ID
  my $slice
      = $slice_adaptor
          -> fetch_by_gene_stable_id(
                  $gene_id
                  );
  my $sequence = $slice -> subseq(1,200);
  return $sequence;
}#------------------------------------------------------
