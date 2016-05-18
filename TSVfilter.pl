#! /usr/bin/perl 
=begin
===========================
Filtering cols in TSV files
===========================
Script to select colss to keep in a tsv file.
Command line arguments:
	-tsv_file_name -> Nombre del archivo tsv
	-out_file_name -> Nombre del archivo de salida
	--fields -> Si está presente, sólo muestra los títulos de las columnas
	-v -> Si se especifica, muestra las lineas impresas en la terminal
	-
=cut
use Getopt::Long; # Para leer argumentos desde la linea de comandos
# Declare variables to hold arguments
my $tsvfile_name = ''; my $out_name = ''; my $fields = ''; my $vervose;
GetOptions(
	'tsvfile=s' => \$tsvfile_name,
	'out=s' => \$out_name,
	'fields' => \$fields,
	'verbose' => \$verbose
	);


# Command line argumments passed...
print "Command line argumments passed:\n";
print " --tsvfile: '$tsvfile_name'\n --out: '$out_name'\n --fields: '$fields'\n v: '$verbose'\n";


unless ($tsvfile_name)
{
	die 
	"Usage: ./TSVfilter --tsvfile=<tsvfile> [--out=<outfile>] [--fields] [--verbose]";
}


# Open input file
print "Opening input file: $tsvfile_name... \n";
open (my $tsvfile, "<", $tsvfile_name) or die "Can't open $tsvfile_name : $!";

unless($fields)
{
	# Open output file
	print "Opening output file: $out_name...\n";
	open (my $out, ">", $out_name) or die "Can't open $out_name : $!";
}


# Get the fields of the TSV file
my @fields = split(/\t/, <$tsvfile>);
chomp @fields;
# Print them...
print "Fields found:\n";
foreach my $i (0..$#fields)
{
	print "$i : $fields[$i] \n";
}

unless($fields)
{
	# Get user to select removing fields
	print "Which of those do you wish to remove? (separate by commas, spaces or tabs)\n";
	chomp($remove = <>);
	# Filter user input
	@remove = split(/[, \t]+/, $remove);
	# Now which lines are staying?
	my @stay = ();
	foreach my $i (0..$#fields)
	{
		push(@stay, $i) unless (any($i, @remove)); 
	}
	
	# Removal and output operation
	print "Now doing output operation of selected fields in $out_name\n";
	while (<$tsvfile>)
	{
		my @line = split(/\t/, $_);
		chomp @line;
		foreach (@stay)
		{
			print $out "$line[$_]\t";
			print "$line[$_]\t" if ($verbose);
		}
		print $out "\n";
		print "\n" if ($verbose);
	}
}

sub any
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $key = shift;
	my @array = shift;
	foreach my $i (@array)
	{
		if ($key == $i)
		{
			return 1;
		}
		return 0;
	}
	
}