#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./tsv_col_selector.pl [--in=<tsvfile>] [--out=<outfile>] [--cols=<field1>,<field2>,..] [--n-cols=n1,n2,...] [--help]

==================================================
Expand the INFO column in the TSV (from VCF) file.
==================================================

Script to expand the column INFO of a TSV file in the format of
a VCFv4.1.

Command-line arguments:

	-i, --in, --tsv
		Name of the input tsv file.
		If not present, input from standard input.
		
	-o, --out
		Name of the output file.
		If not present output to standard output.
		
	-h, --help
		Show this text and exit.
		
A VCFv4.1 INFO column has the next fields:

	INFO=<ID=CONSEQUENCE,Number=.,Type=String,Description="Mutation consequence predictions annotated by SnpEff (subfields: gene_symbol|gene_affected|gene_strand|transcript_name|transcript_affected|protein_affected|consequence_type|cds_mutation|aa_mutation)">

	INFO=<ID=OCCURRENCE,Number=.,Type=String,Description="Mutation occurrence counts broken down by project (subfields: project_code|affected_donors|tested_donors|frequency)">

	INFO=<ID=affected_donors,Number=1,Type=Integer,Description="Number of donors with the current mutation">

	INFO=<ID=mutation,Number=1,Type=String,Description="Somatic mutation definition">

	INFO=<ID=project_count,Number=1,Type=Integer,Description="Number of projects with the current mutation">

	INFO=<ID=tested_donors,Number=1,Type=Integer,Description="Total number of donors with SSM data available">
	
A typical INFO annotation looks like this:

CONSEQUENCE=||||||intergenic_region||,RP11-413P11.1|ENSG00000224445|1|RP11-413P11.1-001|ENST00000438829||upstream_gene_variant||;OCCURRENCE=SKCA-BR|1|66|0.01515;affected_donors=1;mutation=C>T;project_count=1;tested_donors=10033
	
Author: Andrés García García @ Sept 2016.

END

# Description of the INFO field in VCFv4.1

$INFO_field_description = <<END;
INFO=<ID=CONSEQUENCE,Number=.,Type=String,Description="Mutation consequence predictions annotated by SnpEff (subfields: gene_symbol|gene_affected|gene_strand|transcript_name|transcript_affected|protein_affected|consequence_type|cds_mutation|aa_mutation)">
INFO=<ID=OCCURRENCE,Number=.,Type=String,Description="Mutation occurrence counts broken down by project (subfields: project_code|affected_donors|tested_donors|frequency)">
INFO=<ID=affected_donors,Number=1,Type=Integer,Description="Number of donors with the current mutation">
INFO=<ID=mutation,Number=1,Type=String,Description="Somatic mutation definition">
INFO=<ID=project_count,Number=1,Type=Integer,Description="Number of projects with the current mutation">
INFO=<ID=tested_donors,Number=1,Type=Integer,Description="Total number of donors with SSM data available">
END

use Getopt::Long; # To parse command-line arguments


#===============>> BEGINNING OF MAIN ROUTINE <<=====================

# Declare variables to hold command-line arguments
my $tsvfile_name = ''; my $out_name = ''; my $fields = '';
my $cols = ''; my $n_cols = '';
GetOptions(
	'i|in|tsv=s' => \$tsvfile_name,
	'o|out=s' => \$out_name,
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

# Get the position of the INFO field
my $INFO_pos = col_number_from_name("INFO", \@fields);

# Get the names for the info field
my @INFO_fields = `echo '$INFO_field_description' | facilitate_INFO_fields.pl -f`;
chomp @INFO_fields;

delete $fields[$INFO_pos]; # Remove the original header to expand it
foreach my $field (@INFO_fields)
{
	push @fields, "INFO_$field";
}
array_to_tsvfile(\@fields, $out);

while (my @line = get_tsv_line($tsvfile))
{
	my $INFO = $line[$INFO_pos];
	splice @line, $INFO_pos, 1; # Remove collapsed data
	
	my @append_to_current_line = ();
	foreach my $field (@INFO_fields)
	{
		my $field_re = qr/$field/;
		$INFO =~ /${field_re}=([^;]*);?/;
		push @append_to_current_line, $1;
	}
	push @line, @append_to_current_line;
	
	array_to_tsvfile(\@line, $out);
	
	#Append to the current line
	my $line = join("\t", @line);
	
	print $out "$line\n";
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
		print "$i : '$array[$i]'\n";
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
	my $outfile = shift;
	
	my $line = join("\t", @array);
	print $out "$line\n";
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

sub col_number_from_name
# Get the numeric positions of the given cols
{
	my $col_name = shift;
	my @fields = @{shift()};
	
	my $col_number;
	
	# Get the column numbers
	foreach my $i (0..$#fields)
	{
		return $i if $col_name eq $fields[$i];
	}
	
	return undef;
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