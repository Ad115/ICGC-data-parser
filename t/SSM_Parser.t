#! /usr/bin/perl
use v5.10.0;
use strict;
use warnings;
use Test::More;

use lib '../lib';
	use ICGC_Data_Parser::Tools qw(:general_io :debug);
	use ICGC_Data_Parser::SSM_Parser qw(parse_fields);

# -------------> BEGIN TESTING <------------------------------

	diag( "Testing ICGC_Data_Parser::SSM_Parser $ICGC_Data_Parser::SSM_Parser::VERSION, Perl $], $^X" );
	
	# parse_fields
		# Parse a line
		my $fields = 'a	b	c	d';
		my $parsed = parse_fields $fields;
		# Is the result defined?
		ok( defined $parsed->{a} and
			defined $parsed->{b} and
			defined $parsed->{c} and
			defined $parsed->{d}
		);
		# Is the result correct?
		ok( @{$parsed}{qw(a b c d)} eq qw(0 1 2 3) );
	
# -------------> FINISH TESTING <-----------------------------
done_testing(); 
