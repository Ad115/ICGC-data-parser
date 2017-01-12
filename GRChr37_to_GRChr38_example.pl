#! /usr/bin/env perl

use strict;
use warnings;
 
use HTTP::Tiny;
 
my $http = HTTP::Tiny->new();
 
my $server = 'http://rest.ensembl.org';
my $ext = '/map/human/GRCh37/X:1000000..1000000:1/GRCh38?';
my $response = $http->get($server.$ext, {
  headers => { 'Content-type' => 'application/json' }
});
 
die "Failed!\n" unless $response->{success};
 
 
use JSON;
use Data::Dumper;
if(length $response->{content}) {
  my $hash = decode_json($response->{content});
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Indent = 1;
  print Dumper $hash;
  print "\n";
  print "$hash\n";
  my %real_hash = %{$hash};
  print %real_hash;
  print "\n";
  my $mappings = $real_hash{'mappings'};
  my @mappings = @{$mappings};
  print $mappings; print "\n";
  print @mappings; print "\n";
  my %mappings = %{$mappings[0]};
  print %mappings; print "\n";
  my %mapped = %{$mappings{'mapped'}};
  my %original = %{$mappings{'original'}};
  print %mapped; print "\n";
  print %original; print "\n";
  print "\n";
  print %{$mappings{'mapped'}}; print "\n";
  print %{$mappings{'original'}}; print "\n";
  print "\n";
  print ${{ %{ ${{ %{ @{ ${{%{$hash}}}{'mappings'} }[0] } }}{'mapped'} } }}{'assembly'}; print "\n";
  %mapped = %{ ${{ %{ @{ ${{ %{$hash} }}{'mappings'} }[0] } }}{'mapped'} };
  print $mapped{'assembly'}; print "\n";
  
  print "\n";
}