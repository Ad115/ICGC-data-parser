#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./tsv_col_selector.pl [--in=<tsvfile>] [--out=<outfile>] [--cols=<field1>,<field2>,..] [--n-cols=n1,n2,...] [--help]

===========================
Filtering cols in TSV files
===========================

Script to select columns to keep in a tsv file.
Command-line arguments:

	-i, --in, --tsv
		Name of the input tsv file.
		If not present, input from standard input.
		
	-o, --out
		Name of the output file.
		If not present output to standard output.
		
	-c, --cols
		Names of the fields to print.
		It is a comma-separated list.
		
	-n, --n-cols
		Numbers of the fields to print.
		Is a comma-separated list.
		
		
	-s, --show-fields
		Show available fields and exit.
		
	-h, --help
		Show this text and exit.
	
Author: Andrés García García @ Sept 2016.

END



use Getopt::Long; # To parse command-line arguments


#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Declare variables to hold command-line arguments
my $tsvfile_name = ''; my $out_name = ''; my $fields = '';
my $cols = ''; my $n_cols = '';
GetOptions(
	'i|in|tsv=s' => \$tsvfile_name,
	'o|out=s' => \$out_name,
	'c|cols=s' => \$cols,
	'n|n-cols=s' => \$n_cols,
	's|show-fields' => \$fields,
	'h|help' => \$help
	);

# Open input file
my $tsvfile = STDIN;
if($tsvfile_name)  { open_input($tsvfile, $tsvfile_name); }

# Open output file
my $out = STDOUT;
if ($out_name)  { open_output($out, $out_name,); }

# Check if user asked for help
if($help) { print_and_exit($doc_str); }

# Get the fields available in the TSV file
my @fields = get_tsv_line($tsvfile);

# Check if user only asked for the fields available
if ($fields)  { print_array_and_exit(\@fields); }

# Get the user-given columns
@col_numbers = get_col_numbers($cols, $n_cols, \@fields);

# Output operation
array_to_tsvfile(\@fields, \@col_numbers, $out);
while (my @line = get_tsv_line($tsvfile))
{
	array_to_tsvfile(\@line, \@col_numbers, $out);
}

#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


#	===========
#	Subroutines
#	===========

sub get_tsv_line
# Get the names of the columns in the TSV file, whose handler is passed in the call.
# It assumes the names are in the first row.
{
	my $tsvfile = shift;
	
	# Skip comments
	my $line;
	do	{ $line = <$tsvfile>; }
	while($line =~ /^#.*/);
		
	my @fields = split(/\t/, $line);
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
		print "$array[$i]\n";
	}
}#-----------------------------------------------------------

sub print_numbered_array
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

sub any
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $key = shift;
	my @array = @{shift()};
	
	foreach my $i (@array)
	{
		if ($key eq $i)
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
	
	my $max_index = $indexes[$#indexes];
	foreach my $i (@indexes)
	{
		print $outfile "$array[$i]";
		print $outfile "\t" unless ($i == $max_index);
	}
	print $outfile "\n";
}#-----------------------------------------------------------

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
}#-----------------------------------------------------------

sub print_array_and_exit
# Prints given message and exits
{
	my @array = @{shift()};
	print_array(\@array);
	exit;
}#-----------------------------------------------------------

sub open_input
# Prints given message and exits
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open input file
	print $message;
	open ($file_handler, "<", $file_name)
		or die "Can't open $file_name for input : $!";
}#-----------------------------------------------------------

sub open_output
# Prints given message and exits
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open output file
	print $message;
	open ($file_handler, ">", $file_name)
		or die "Can't open $file_name for output : $!";
}#-----------------------------------------------------------

sub get_col_numbers
# Get the numeric positions of the given cols
{
	my $col_names = shift;
	my $n_cols = shift;
	my @fields = @{shift()};
	
	# Get the columns from the list of names
	my @col_numbers = col_numbers_from_names($col_names, \@fields);
	
	# Get the columns from the list of numbers
	my @n_cols = split(',', $n_cols);
	
	# Join both lists
	push(@col_numbers, @n_cols);
	
	# Sort joint list
 	@col_numbers = sort {$a <=> $b} @col_numbers;
	
	# Remove repeated elements
	@col_numbers = uniq(\@col_numbers);
	
	return @col_numbers;
}#-----------------------------------------------------------

sub col_numbers_from_names
# Get the numeric positions of the given cols
{
	my $col_names = shift;
	my @fields = @{shift()};
	
	my @col_names = split(',', $col_names);
	my @col_numbers = ();
	
	# Get the column numbers
	foreach my $i (0..$#fields)
	{
		push(@col_numbers, $i) if any($fields[$i], \@col_names);
	}
	
	return @col_numbers;
}#-----------------------------------------------------------

sub print_filtered_array
# Print only selected entries from the array.
{
	my @array = @{shift()};
	my @indices = @{shift()};
	my $message = shift;
	
	my @filtered = filter(\@array, \@indices);
	print_numbered_array(\@filtered, $message);
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

sub uniq
# Remove repeated entries from array
{
	my @array = @{shift()};
	my %seen;
	
	return grep !($seen{$_}++), @array;
}