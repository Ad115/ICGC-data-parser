#! /usr/bin/perl

system("rm ./*tmp.tsv");
system("rm ./*.plot.tsv");
my $directory = "..";
my @files = `ls -1 $directory`;
chomp @files;


foreach my $file (@files)
{
	if( $file =~ /(.*?)-count.tsv/ )
	{
		my $temp_file = "$1.tmp.tsv";
		my $final_file = "$1.plot.tsv";
		
		# Add header mark
		my $header = `head -n 1 $directory/$file`;
		chomp $header;
		$header = "## ".$header;
		system("echo \"$header\" | cat > $temp_file");
		
		# Get the rest of the file 
		system("tail -n +2  < $directory/$file >> $temp_file");
		
		# Cleanup unnecessary columns
		system("tsv_col_selector.pl -n 1,0 --in=./$temp_file --out=./$final_file");
		
		# Clean files
		system("rm ./$temp_file");
	}
}

