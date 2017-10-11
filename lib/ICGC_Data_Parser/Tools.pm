
package ICGC_Data_Parser::Tools;
	use strict;
	use warnings;
	use Exporter qw'import';

	use version; 
		our $VERSION = qv("v0.0.1");
	
	our @EXPORT_OK = qw'print_and_exit open_input open_output print_fields tweeter tweet full_path uniq';
	our %EXPORT_TAGS = (
		'general_io'	=>	[qw'print_and_exit open_input open_output print_fields full_path'],
		'debug'	=>	[qw'tweeter tweet']
	);

#============================================================

use Data::Dumper; # To preety print hashes easily
	local $Data::Dumper::Purity = 1;
	local $Data::Dumper::Sortkeys = 1;

#============================================================


#	===========
#	Subroutines
#	===========

    sub tweeter
    # Returns the preety printed content of the given structure
    {
        my $structure = shift;
        my $name = shift;

        return Data::Dumper->Dump([$structure], [$name]);
    }#-----------------------------------------------------------

    sub tweet
    # Prints the content of the given structure
    {
        my $structure = shift;
        my $name = shift;

        print tweeter($structure, $name);
    }#-----------------------------------------------------------

    sub uniq
    # Remove repeated entries from array
    {
        my @array = @_;

        my %seen;
        return grep !($seen{$_}++), @array;
    }#-----------------------------------------------------------


	sub print_and_exit
	# Prints given message and exits
	{
		my $message = shift;
		print $message if ($message);
		exit;
	}#-----------------------------------------------------------

	sub open_input
	# Prints given message and exits
	{
		my $file_handler = shift;
		my $file_name = shift;
		my $message = shift;

		# Open input file
		print $message if ($message);
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
# 		print $message if ($message);
		open ($file_handler, ">", $file_name)
			or die "Can't open $file_name for output : $!";
	}#-----------------------------------------------------------

    sub print_fields
    # USAGE: print_fields(\%hash, \@keys)
    # Print orderly the values corresponding to the given keys of the hash
    # Prints in TSV format
    {
    	my $output = shift;
    	my %hash = %{shift()};
    	my @keys = @{shift()};

    	# Print the given fields
    	foreach my $key (@keys)
    	{
    		print $output ($hash{$key}) ? "$hash{$key}\t" : "\t";
    	}
    	print "\n";
    }#-----------------------------------------------------------
    
	sub full_path
	# Recieves a file name, returns the absolute path
	{
		my $path = shift;

		use File::Spec;
		return File::Spec->rel2abs( $path ) ;
	}#-----------------------------------------------------------


    #============================================================


1; # Return success
