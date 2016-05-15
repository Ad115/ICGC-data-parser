#! /usr/bin/perl -s
=begin
===========================
Filtering rows in TSV files
===========================
Script to select rows to keep in a tsv file.
Command line arguments:
	-tsv_file_name -> Nombre del archivo tsv
	-outfile -> Nombre del archivo de salida
	-v -> Si se especifica, muestra las lineas impresas en la terminal
=cut
use List::Util qw(any);


# Open input file
print "Opening input file: $tsv_file_name... \n";
open (my $tsv_file, "<", $tsv_file_name) or die "Can't open $tsv_file_name: $!";

# Open output file
print "Opening output file: $out_file_name...\n";
open (my $out_file, ">", $out_file_name) or die "Can't open $out_file_name: $!";

# Get the fields of the TSV file
my @fields = split(/\t/, <$tsv_file>);
chomp @fields;
# Print them...
print "Fields found:\n";
foreach my $i (0..$#fields)
{
	print "$i : $fields[$i] \n";
}

# Get user to select removing fields
print "Which of those do you wish to remove? (separate by commas, spaces or tabs)\n";
chomp($remove = <>);
# Filter user input
@remove = split(/[, ]+/, $remove);
# Now which lines are staying?
my @stay = ();
foreach my $i (0..$#fields)
{
	push(@stay, $i) unless (any {$i == $_} @remove); 
}

# Removal and output operation
print "Now doing output operation of selected fields in $out_file_name\n";
while (<$tsv_file>)
{
	my @line = split(/\t/, $_);
	chomp @line;
	foreach (@stay)
	{
		print $out_file "$line[$_]\t";
		print "$line[$_]\t" if ($v);
	}
	print $out_file "\n";
	print "\n" if ($v);
}