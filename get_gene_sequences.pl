#! /usr/bin/env perl

use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';

# Connect to the Ensembl database
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
    -user => 'anonymous'
    );
    
print "Input genes to query...\n";
my @genes = array_input();

foreach my $gene_name (@genes)
{
    print "GENE\t $gene_name \n";
    
    # Declare a gene adaptor to get the gene
    my $gene_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Gene' );
    
    # Declare a gene handler with the given gene
    my $gene = $gene_adaptor->fetch_by_display_label($gene_name);
    
    # Get the gene's EnsembleStableID
    my $gene_id = $gene->stable_id();
    print "GENE_ID\t $gene_id \n";
    
    # Declare a slicer to get the sequence
    my $slice_adaptor 
        = $registry -> get_adaptor('Human', 'Core', 'Slice');
    
    # Point a slice to where the gene is located, using the gene's ID
    my $slice 
        = $slice_adaptor 
            -> fetch_by_gene_stable_id(
                    $gene_id
                    );
    
    
    my $sequence1 = $slice -> subseq(1,200);
    print "$sequence1 \n";
}

sub array_input
# Gets input from user as scalars separated by comma, space or tabs
# Returns an array with the input values
{
	# Get input as string, remove trailing newlines
	my $input;
	chomp($input = <>);
	# Separate into values
	my @input = split(/[, \t]+/, $input);
	return @input;
}#------------------------------------------------------