#! /usr/bin/perl

my $results_path = "../../prev-results";
my @files = `ls -1 $results_path`;
chomp @files;


foreach my $file (@files)
{
	if( $file =~ /(.*?).tsv/ )
	{
		system("cut -f 4,5,6 < $results_path/$file | sort -h | uniq -c > $results_path/$1-count.txt");
	}
}

