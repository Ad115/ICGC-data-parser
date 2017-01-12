#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./tsv_col_sort.pl [--in=<tsvfile>] [--out=<outfile>] [--col=<field> | --n-col=n] [--help]

===========================
Sort by column in TSV files
===========================

Script to sort a TSV file by the values in a column
Command-line arguments:

	-i, --in, --tsv
		Name of the input tsv file.
		If not present, input from standard input.
		
	-o, --out
		Name of the output file.
		If not present output to standard output.
		
	-c, --col
		Name of the column to sort by.
		
	-n, --n-col
		Number of the column to sort by.
		
	-s, --show-fields
		Show available fields and exit.
		
	-h, --help
		Show this text and exit.
	
Author: Andrés García García @ September 2016.

END



use Getopt::Long; # To parse command-line arguments



#=============>> BEGINNING OF MAIN ROUTINE <<===================


# Declare variables to hold command-line arguments
my $tsvfile_name = ''; my $out_name = ''; my $fields = '';
my $col = ''; my $n_col = '';
GetOptions(
	'i|in|tsv=s' => \$tsvfile_name,
	'o|out=s' => \$out_name,
	'c|col=s' => \$col,
	'n|n-col=s' => \$n_col,
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

# Get the user-given column
my $col_number = get_col_number($col, $n_col, \@fields);

# Get the complete file
my @all_lines = ();
my @sort_column = ();
my $i=0;
while (my $line = <$tsvfile>)
	{
		chomp $line;
		push(@all_lines, $line);
		my @fields = split(/\t/, $line);
		push(@sort_column, $fields[$col_number]);
		$i++;
	}

# Get the positions of the sorted file
my @sorted_order = get_sorting(\@sort_column);

# Print the file in the sorted order
my @all_fields = (0..$#fields);
array_to_tsvfile(\@fields, \@all_fields, $out);
print_sorted_array(\@all_lines, \@sorted_order);




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
	
	foreach (@indexes)
	{
		print $outfile "$array[$_]\t";
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

sub get_col_number
# Get the numeric positions of the given cols
{
	my $col_name = shift;
	my $n_col = shift;
	my @fields = @{shift()};
	my $col_number;

	$col_number = $n_col if $n_col;
	
	if ($col_name) # If user proportionated the column name
	{
		# Get the columns from the list of names
		$col_number = col_number_from_name($col_name, \@fields);
	}
	
	return $col_number;
}#-----------------------------------------------------------

sub col_number_from_name
# Get the numeric positions of the given cols
{
	my $col_name = shift;
	my @fields = @{shift()};
	
	my $col_number;
	# Get the column number
	foreach my $i (0..$#fields)
	{
		return $i if ( $fields[$i] eq $col_name );
	}
	print("Column number $i not found\n");
	return "";
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
}#-----------------------------------------------------------

sub get_back_numbered_col
# Remove repeated entries from array
{
	my $file = shift;
	my $col_number;
	my @back_numbered_lines = ();
	my $line;
	
	my $i=0;
	while (my @line = getTSVline($tsvfile))
	{
		$line = join('\t', $line[$col_number], $i++);
		push(@back_numbered_lines, $line);
	}
	return @back_numbered_lines;
}#-----------------------------------------------------------

sub get_sorting
{
	my @array = @{shift()};
	
	my %initial_positions = ();
	
	# Save the current ordering
	foreach my $i (0..$#array)
	{
		$initial_positions{$array[$i]} = $i;
	}
	
	# Sort the array
	@array = sort {$a <=> $b} @array;
	
	# Save the changes
	my @sorted_positions = ();
	foreach my $i (0..$#array)
	{
		my $position = $initial_positions{$array[$i]};
		push(@sorted_positions, $position);
	}
	
	return @sorted_positions;
}#-----------------------------------------------------------

sub print_sorted_array
{
	my @array = @{shift()};
	my @ordered_positions = @{shift()};
	my $message = shift;
	
	print $message;
	foreach my $i (1..$#ordered_positions)
	{
		print "$array[$ordered_positions[$i]]\n";
	}
}#-----------------------------------------------------------