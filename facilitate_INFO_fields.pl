#! /usr/bin/perl 


my $doc_str = <<END;

Usage: ./facilitate_INFO_fields.pl --description="INFO=..." [--help]

==========================================
Get the names of INFO fields and subfields
==========================================

From the description of the fields and subfields in INFO field of a VCF file, get the names to facilitate the expansion of this column.

Input:
-----
	The description(s) in the format below.
	
	
Output:
------
	The corresponding field (subfields) names, one in each line, in the format:
		
		INFO_<Field name>_<Subfield name>
		

Command-line arguments:
----------------------
		
	-h, --help
		Show this text and exit.
		
	-f, --no-subfields
		Only show fields, not expand them or the subfields.
		
		
		
As an example and the intended use case, VCFv4.1 INFO column description is in the next format:

	INFO=<ID=CONSEQUENCE,Number=.,Type=String,Description="Mutation consequence predictions annotated by SnpEff (subfields: gene_symbol|gene_affected|gene_strand|transcript_name|transcript_affected|protein_affected|consequence_type|cds_mutation|aa_mutation)">
	INFO=<ID=OCCURRENCE,Number=.,Type=String,Description="Mutation occurrence counts broken down by project (subfields: project_code|affected_donors|tested_donors|frequency)">
	INFO=<ID=affected_donors,Number=1,Type=Integer,Description="Number of donors with the current mutation">
	INFO=<ID=mutation,Number=1,Type=String,Description="Somatic mutation definition">
	INFO=<ID=project_count,Number=1,Type=Integer,Description="Number of projects with the current mutation">
	INFO=<ID=tested_donors,Number=1,Type=Integer,Description="Total number of donors with SSM data available">
	
A typical INFO annotation looks like this:

CONSEQUENCE=||||||intergenic_region||,RP11-413P11.1|ENSG00000224445|1|RP11-413P11.1-001|ENST00000438829||upstream_gene_variant||;OCCURRENCE=SKCA-BR|1|66|0.01515;affected_donors=1;mutation=C>T;project_count=1;tested_donors=10033

CONSEQUENCE=||||||||||||||||;OCCURRENCE=|||;affected_donors=;mutation=;project_count=;tested_donors=
	
Author: Andrés García García @ Sept 2016.

END

use Getopt::Long; # To parse command-line arguments


#===============>> BEGINNING OF MAIN ROUTINE <<=====================


# Declare variables to hold command-line arguments
my $description = ''; my $help = ''; my $no_subfields;
GetOptions(
	'h|help' => \$help,
	'f|no-subfields' => \$no_subfields
	);

# Check if user asked for help
if($help) { print_and_exit($doc_str); }

while (my $line = <STDIN>)
{
	# Get field ID
	if ( $line =~ /INFO.*ID=([a-z_A-Z]+)/ )
	{
		my $ID = $1;
		
		print $ID."\n" if ($no_subfields);
		
		unless ($no_subfields)
		{
			print "INFO_$ID\n";
			
			# Get subfields if any
			my $subfields;
			if ($line =~ /subfields:\s?(.*?)\)/)
			{
				$subfields = $1;
			}
			my @subfields = split('\|', $subfields);
			
			# Assemble and print the final names
			foreach my $subfield (@subfields)
			{
				print "INFO_$ID\_$subfield\n" if ($ID);
			}
		}
	}
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