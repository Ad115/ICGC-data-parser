#! /usr/bin/env perl

my $doc_str = <<END;

Usage: $0 [--help]

=======================
 List all databases
=======================

Queries [Ensembl](www.ensembl.org) through the Ensembl Perl API and lists all the
available databases.

Command-line arguments:

	-h, --help
		Show this text and exit.
		
Author: Based on an example in:
[Ensembl Perl API's core tutorial](http://www.ensembl.org/info/docs/api/core/core_tutorial.html).

END

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Getopt::Long; # To parse command-line arguments

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

	my $help;
	GetOptions('h|help' => \$help);
	
	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }

	# Initialize a connection to the db.
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
