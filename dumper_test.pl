#! /usr/bin/perl


use Data::Dumper;
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 1;
my %hash = ('abc' => 123, 'def' => [4,5,6]);
print Dumper(\%hash);
