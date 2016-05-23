#! /usr/bin/perl 
=begin
===========================
Filtering cols in TSV files
===========================

Script to select columns to keep in a tsv file.
Command-line arguments:
	--tsvfile -> Name of the input tsv file, the only required argument
	--out -> Name of the output file
	--fields -> If present, only show column titles
=cut

use Getopt::Long; # To parse command-line arguments


#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Declare variables to hold command-line arguments
my $tsvfile_name = ''; my $out_name = ''; my $fields = '';
GetOptions(
	'tsvfile=s' => \$tsvfile_name,
	'out=s' => \$out_name,
	'fields' => \$fields
	);


# Command line argumments passed...
print "Command line argumments passed:\n";
print " --tsvfile: '$tsvfile_name'\n --out: '$out_name'\n --fields: '$fields'\n";

# Input file is required
unless ($tsvfile_name)
{
	die 
	"Usage: ./TSVfilter --tsvfile=<tsvfile> [--out=<outfile>] [--fields]";
}

# Open input file
print "\nOpening input file: $tsvfile_name... \n";
open (my $tsvfile, "<", $tsvfile_name) 
	or die "Can't open $tsvfile_name : $!";

# Get the fields of the TSV file and print them
my @fields = getTSVline($tsvfile);
# Print them...
print_array(\@fields, "\nFields found:\n");

unless($fields)
{
	# Get user to select removing fields
	print "\nWhich of those do you wish to remove?";
	print "(separate by commas, spaces or tabs)\n";
	my @remove = array_input();
	print_filtered_array(\@fields, \@remove, "\nFields to remove...\n");
	
	# Now which columns are staying?
	my @all_fields = (0..$#fields);
	my @stay = complement(\@remove, \@all_fields);
	print_filtered_array(\@fields, \@stay, "\nFields to print...\n");
	
	# Open output file
	print "\nOpening output file: $out_name...\n";
	open (my $out, ">", $out_name) 
		or die "Can't open $out_name : $!";

	# Removal and output operation
	print "\nNow doing output operation of selected fields in $out_name\n";
	array_to_tsvfile(\@fields, \@stay, $out);
	while (my @line = getTSVline($tsvfile))
	{
		array_to_tsvfile(\@line, \@stay, $out);
	}
}
#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


#	===========
#	Subroutines
#	===========

sub getTSVline
# Get the names of the columns in the TSV file, whose handler is passed in the call.
# It assumes the names are in the first row.
{
	my $tsvfile = shift;
	my @fields = split(/\t/, <$tsvfile>);
	chomp @fields;
	return @fields;
}#-----------------------------------------------------------

sub print_array
# Prints the content of the passed array
{
	my @array = @{shift()};
	my $message = shift;
	
	print $message;
	foreach my $i (0..$#array)
	{
		print "$i : $array[$i] \n";
	}
}#-----------------------------------------------------------

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
}#-----------------------------------------------------------

sub print_filtered_array
# Print only selected entries from the array.
{
	my @array = @{shift()};
	my @indices = @{shift()};
	my $message = shift;
	
	my @filtered = filter(\@array, \@indices);
	print_array(\@filtered, $message);
}#-----------------------------------------------------------

sub filter
# Get only selected entries from the array.
{
	my @array = @{shift()};
	my @indexes = @{shift()};
	my @filtered = ();
	
	foreach my $i (@indexes)
	{
		push(@filtered, $array[$i]);
	}
	return @filtered;
}#-----------------------------------------------------------

sub complement
# Gets the complement of an array given a universe (as another array)
# Usage: @complement = complement(\@original, \@universe)
{
	my @original = @{shift()};
	my @universe = @{shift()};
	my @complement = ();
	
	foreach my $i (0..$#universe)
	{
		push(@complement, $universe[$i]) 
			unless any	($universe[$i], \@original);
	}
	return @complement;
}#-----------------------------------------------------------

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
}#-----------------------------------------------------------

sub array_to_tsvfile
# Print selected entries from the array to output file.
# Usage array_to_file(\@array, \@indexes, $outfile)
{
	my @array = @{shift()};
	my @indexes = @{shift()};
	my $outfile = shift;
	
	foreach (@indexes)
	{
		print $outfile "$array[$_]\t";
	}
	print $outfile "\n";
}#-----------------------------------------------------------