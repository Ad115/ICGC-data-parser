#! /usr/bin/perl 
=begin
===========================
Filtering cols in TSV files
===========================
Script to select colss to keep in a tsv file.
Command line arguments:
	--tsvfile -> Nombre del archivo tsv
	--out -> Nombre del archivo de salida
	--fields -> Si está presente, sólo muestra los títulos de las columnas
	--interactive -> Si está presente, se ejecuta de forma interactiva
	-
=cut
use Getopt::Long; # Para leer argumentos desde la linea de comandos
# Declare variables to hold arguments
my $tsvfile_name = ''; my $out_name = ''; my $fields = '';
GetOptions(
	'tsvfile=s' => \$tsvfile_name,
	'out=s' => \$out_name,
	'fields' => \$fields
	);


# Command line argumments passed...
print "Command line argumments passed:\n";
print " --tsvfile: '$tsvfile_name'\n --out: '$out_name'\n --fields: '$fields'\n";


unless ($tsvfile_name)
{
	die 
	"Usage: ./TSVfilter --tsvfile=<tsvfile> [--out=<outfile>] [--fields]";
}


# Open input file
print "Opening input file: $tsvfile_name... \n";
open (my $tsvfile, "<", $tsvfile_name) or die "Can't open $tsvfile_name : $!";


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
	print "Fields to remove...\n";
	foreach my $i (0..$#remove)
	{
		print "$i : $remove[$i] \n";
	}
	# Now which lines are staying?
	my @stay = ();
	foreach my $i (0..$#fields)
	{
		push(@stay, $i) unless (any($i, \@remove)); 
	}
	print "Fields that are staying...\n";
	foreach my $i (0..$#stay)
	{
		print "$i : $stay[$i] \n";
	}
	
	# Open output file
	print "Opening output file: $out_name...\n";
	open (my $out, ">", $out_name) or die "Can't open $out_name : $!";
	# Removal and output operation
	print "Now doing output operation of selected fields in $out_name\n";
	foreach (@stay)
	{
		print $out "$fields[$_]\t";
	}
	print $out "\n";
	while (<$tsvfile>)
	{
		my @line = split(/\t/, $_);
		chomp @line;
		foreach (@stay)
		{
			print $out "$line[$_]\t";
		}
		print $out "\n";
	}
}

sub any
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $key = shift;
	my @array = @{shift()};
	
	foreach my $i (@array)
	{
		if ($key == $i)
		{
			return 1;
		}
	}
	return 0;
}