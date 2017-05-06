#! /usr/bin/perl -T
use v5.10.0;
use strict;
use warnings;
use Test::More;

use lib '../lib';
	use ICGC_Data_Parser::Tools qw(uniq);

# -------------> BEGIN TESTING <------------------------------

	diag( "Testing ICGC_Data_Parser::Tools $ICGC_Data_Parser::Tools::VERSION, Perl $], $^X" );
	
	# tweet/tweeter
		# NOT IMPLEMENTED
	
	# uniq
	my @repeated = qw(a a a b a b c c c);
	ok(uniq \@repeated eq 'a b c');
	
	# print_and_exit
		# NOT IMPLEMENTED
	
	# open_input/open_output
		# NOT IMPLEMENTED
	
	# print_fields
		# NOT IMPLEMENTED
	
	# full_path
		# NOT NEEDED

# -------------> FINISH TESTING <-----------------------------
done_testing();