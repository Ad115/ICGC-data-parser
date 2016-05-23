#! /usr/bin/perl 
=begin

Filtering cols in TSV files
===========================

Script to select columnss to keep in a tsv file.
Command-line arguments:
	-tsv_file_name -> Name of the input tsv file, the only required argument
	-out_file_name -> Name of the output file
	--fields -> If present, only show column titles
	--verbose -> If present, print the process progres to stdout
=cut

use Getopt::Long; # To parse command-line arguments


#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Declare variables to hold command-line arguments
my $tsvfile_name = ''; my $out_name = ''; my $fields = ''; my $vervose;
GetOptions(
	'tsvfile=s' => \$tsvfile_name,
	'out=s' => \$out_name,
	'fields' => \$fields,
	'verbose' => \$verbose
	);


unless ($tsvfile_name)
# Input file is required
{
	die 
	"Usage: ./TSVfilter --tsvfile=<tsvfile> [--out=<outfile>] [--fields] [--verbose]";
}


# Open input file
print "Opening input file: $tsvfile_name... \n";
open (my $tsvfile, "<", $tsvfile_name) 
	or die "Can't open $file_name : $!";

unless($fields)
{
	# Open output file
	print "Opening output file: $out_name...\n";
	open (my $out, ">", $out_name) 
		or die "Can't open $file_name : $!";
}


# Get the fields of the TSV file
#my @fields = getTSVfields($tsvfile);
print <$tsvfile>;
my @fields = split(/\t/, <$tsvfile>);
print_array(@fields);
chomp @fields;
print_array(@fields);
return @fields;
	
# Print them...
print "Fields found:\n";
print_array(@fields);


unless($fields)
{
	# Get user to select removing fields
	print "Which of those do you wish to remove? 
		(numbers separated by commas, spaces or tabs)";
	my @remove = input();
	# Now which lines are staying?
	my @fields_i = (0..$#fields);
	my @stay = complement(\@remove, \@field_n);
	
	# Filter and output operation
	print "Now doing output operation of selected fields in $out_name\n";
	output_fields(@stay, $tsvfile, $out);
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

#===============>> END OF MAIN ROUTINE <<=====================

#-------------------------------------------------------------
#	===========
#	Subroutines
#	===========


sub getTSVfields
# Get the names of the columns in the TSV file, whose handler is passed in the call.
# It assumes the names are in the first row.
{
	my $tsvfile = shift;
	my @fields = split(/\t/, $tsvfile);
	print_array(@fields);
	chomp @fields;
	print_array(@fields);
	return @fields;
}#-----------------------------------------------------------

sub print_array
# Prints the content of the passed array
{
	@array = shift;
	foreach my $i (0..$#array)
	{
		print "$i : $array[$i] \n";
	}
}#-----------------------------------------------------------

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
	
}#-----------------------------------------------------------

sub input
# Gets input from user as scalars separated by comma, space or tabs
# Returns an array with the input values
{
	my @input;
	# Get input as string, remove trailing newlines
	chomp($input = <>);
	# Separate into values
	@input = split(/[, \t]+/, @input);
	return @input;
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
			unless any	($universe[$i], @remove);
	}
	return @complement;
}#-----------------------------------------------------------

sub output_fields
# Print selected fields from input file to output file.
# Usage output_fields(@field_numbers, $inputf_handler, $outputf_handler)
{
	my @fields = shift;
	my $input = shift;
	my $output = shift;
	
	while (<$input>)
	{
		my @line = split(/\t/, $_);
		chomp @line;
		foreach (@fields)
		{
			print $output "$line[$_]\t";
			print "$line[$_]\t" if ($verbose);
		}
		print $output "\n";
		print "\n" if ($verbose);
	}
}#-----------------------------------------------------------