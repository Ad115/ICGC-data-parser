#! /usr/bin/env perl

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Initialize a connection to the db.
print "Waiting connection to database...\n";
my $connection = ensembldb_connect();

my @db_adaptors = @{ $connection->get_all_DBAdaptors() };

foreach my $db_adaptor (@db_adaptors)
{
	my $db_connection = $db_adaptor->dbc();
	
	printf(
		"species/group\t%s/%s\ndatabase\t%s\nhost:port\t%s:%s\n\n", 
		$db_adaptor->species(), $db_adaptor->group(),
		$db_connection->dbname(), $db_connection->host(),
		$db_connection->port()
	);
}

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