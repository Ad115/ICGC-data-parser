#! /usr/bin/env perl

my $doc_str = <<END;

Usage: $0 --chromosome=<n>, --position=<begin|begin-end> [--species=<species>] [--length=<l>] [--help]

========================
 Get specified sequence
========================

Queries [Ensembl](www.ensembl.org) database and gets the sequence in the specified species,
chromosome, position and of the given length (or to the given ending position if a range is given)

Command-line arguments:

	-c, --chromosome
		Chromosome to look in.

	-p, --position
		Position in chromosome of the sequence.
		If a single number, it is the initial position of the sequence.
		If a range, as in 1000023-1000431, obtains the sequence in that range.

	-s, --species (optional)
		Species to query data from, default 'Homo Sapiens'.

	-l, --list-species (optional)
		Lists available species to query data from and exits.

	-L, --length (optional)
		If -p is given a single number, it specifies the total length to get, default 100.
		If -p is given a range, it is ignored.

	-h, --help (optional)
		Show this text and exit.

Author: Andrés García García @ Feb 2017

END

use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Getopt::Long qw(:config bundling); # To parse command-line arguments
use Data::Dumper; # To preety print hashes easily
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION
    my %opts = (
        'species' => 'Homo sapiens', # options with default values
        'length' => '100'
        );
    # Parse command line options
	GetOptions( \%opts,
		'chromosome|c=s',
		'position|p=s',
		'species|s:s',
        'list-species|l',
		'length|L:i',
		'help|h'
		);

	# Check if user asked for help
	if($opts{'help'})  { print_and_exit($doc_str); }

    # Check for bad program calling
    if( ! defined $opts{'list-species'} )
    {
        print_and_exit($doc_str) if (!$opts{'chromosome'} or !$opts{'position'});
    }

    # Get position in chromosome
    my @position;
    if ($opts{'position'} =~ /([0-9]*)-([0-9]*)/)
    {
        @position = ($1, $2);
    }
    else
    {
         @position = ( $opts{'position'}, $opts{'position'}+$opts{'length'} );
    }

## WEB DATA INITIALIZATION
    # Initialize a connection to the db
    my $connection = ensembldb_connect();

    # Check if user asked for the available species
    if( $opts{'list-species'} )
    {
        print_and_exit( "Available species: "
                        .join( ', ', get_available_species() )
                        );
    }

## MAIN QUERY
    # Fetch the genomic region
    my $slice = $connection
                    -> get_adaptor( $opts{'species'}, 'Core', 'Slice' )
                    -> fetch_by_region( 'chromosome', $opts{'chromosome'}, $position[0], $position[1]);

    # Get overlapping genes
    my $overlapping = join ', ', get_overlapping_genes($slice);

    my $sequence = $slice->seq();

    print <<END;
<===============================================================================>
Species: $opts{'species'}
Position: Chromosome $opts{'chromosome'} $position[0]-$position[1] (Overlapped genes: $overlapping)
Sequence: $sequence
<===============================================================================>
END

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
  print STDERR "Waiting connection to database... ";
  $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
      -user => 'anonymous'
      );
  print STDERR "Connected to database!\n";

  return $registry;
}#------------------------------------------------------

sub print_hash
# Prints the content of the passed hash
{
	my %hash = %{shift()};
	my $name = shift;

	print STDERR "$name: ".Dumper \%hash;
}#------------------------------------------------------

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
}#-----------------------------------------------------------

sub get_available_species
# Returns a list of the available species to query in the Ensembl database
{
    my @db_adaptors = @{ $connection->get_all_DBAdaptors() };

    my @species = ();
	foreach my $db_adaptor (@db_adaptors)
	{
        if( lc $db_adaptor->group() eq 'core')
        {
            push @species, $db_adaptor->species();
        }
    }
    return @species;
}#-----------------------------------------------------------

sub get_overlapping_genes
# Returns a list of all genes overlapping the slice
{
	my $slice = shift;

    @overlapping = @{ $slice -> get_all_Genes() };
    return get_display_labels(\@overlapping);
}#-----------------------------------------------------------

sub get_display_labels
# Retuns the list with the display labels of the features in the array
{
	my @features = @{shift()};

	my @display_labels = ();
	foreach my $feature (@features)
	{
		push( @display_labels, $feature -> external_name() );
	}

	return @display_labels;
}#-----------------------------------------------------------
