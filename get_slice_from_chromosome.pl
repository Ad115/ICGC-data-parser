#! /usr/bin/env perl

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Initialize a connection to the db.
print "Waiting connection to database...\n";
my $connection = ensembldb_connect();

my $slice_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Slice' );

my $begin_slice = 10000308;
my $end_slice = 10000308;
my $slice = $slice_adaptor->fetch_by_region( 'chromosome', '1', $begin_slice, $end_slice);

my $sequence = $slice->seq();
print "Sequence CHR 1, 0:1e3:\n$sequence\n";

my $sub_sequence = $slice->subseq(0, 200);
print "\nSubsequence CHR 1, 0:200:\n$sub_sequence\n";

# Query the slice for information about itself
my $coord_system = $slice->coord_system()->name();
my $region = $slice->seq_region_name();
my $start = $slice->start();
my $end = $slice->end();
my $strand = $slice->strand();

print "Slice: $coord_system $region $start-$end ($strand)\n";

#===============>> END OF MAIN ROUTINE <<=====================
 
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