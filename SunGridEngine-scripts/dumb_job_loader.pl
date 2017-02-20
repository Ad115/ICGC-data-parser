#! /usr/bin/env perl

my $doc_str = <<END;

Usage: $0 -n <processes> [--help]

=======================
 Dumb job loader
=======================

Executes dumb_job.sh with a number of processes defined by the command line argument -n

Command-line arguments:

    -n
        Number of processes to execute

    -h, --help
        Show this text and exit.

Author: Andrés García García @ Feb 2017

END

use 5.010; use strict; use warnings; # To have a clean code
use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Getopt::Long; # To parse command-line arguments

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

    my $help; my $n;
    GetOptions(
            'n=i'      => \$n,
            'h|help' => \$help
            );

    # Check if user asked for help
    if($help or !$n) { print_and_exit($doc_str); }

    # Open script for edition and temporary output
    say "$n jobs";
    my $in; my $out;
    open_input(\$in, "dumb_job.sh");
    open_output(\$out, "dumb_job_temp.sh");

    while (<$in>)
    {
        s/JOBNAME/$n-DUMB-JOBS/;
        s/NJOBS/$n/;
        print $out $_;
    }
    close $in; close $out;
    my @out = `cat dumb_job_temp.sh`;
    $"="\n"; print "@out";
    unlink "dumb_job_temp.sh";
#===============>> END OF MAIN ROUTINE <<=====================

    #       ===========
    #       Subroutines
    #       ===========

sub open_input
# Prints given message and opens input file
# Exit with error if it fails to open the file
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open input file
	print $message if $message;
	open ($$file_handler, "<", $file_name)
		|| die "Can't open $file_name for input : $!";
}#-----------------------------------------------------------

sub open_output
# Prints given message and opens file for output
# Exit with error if it fails to open the file
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open output file
	print $message if $message;
	open ($$file_handler, ">", $file_name)
		|| die "Can't open $file_name for output : $!";
}#-----------------------------------------------------------

sub print_and_exit
# Prints given message and exits
{
    my $message = shift;
    print $message;
    exit;
}
