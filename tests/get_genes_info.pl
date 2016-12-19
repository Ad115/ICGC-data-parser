#! /usr/bin/perl

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

	my @genes = ('ENSG00000141510', 'ENSG00000141736', 'ENSG00000135679', 'ENSG00000012048', 'ENSG00000149311', 'ENSG00000123374', '');
	# TP53(ENSG00000141510), HER2(ERBB2)(ENSG00000141736), MDM2(ENSG00000135679), BRCA1(ENSG00000012048), ATM(ENSG00000149311), CDK2(ENSG00000123374)
	my @projects = ('', 'BRCA-EU', 'GBM-EU');

	my $data = "../../data_release_22/ssm.aggregated.vcf";
	my $results_path = "../../results";
	my $error_file = "$results_path/log.err";

	foreach my $project (@projects)
	{
		my $project_str = ($project) ? $project : "All projects";
		print STDERR "Project: $project_str\n";
		
		foreach my $gene (@genes)
		{
			my $gene_str = ($gene) ? $gene : "All genes";
			print STDERR "\tGene: $gene_str\n";
			
			
			##########################
			#	MUTATION ANALYSIS
			##########################
			
			print STDERR "\t\tAnalysis...";
			
			my $header = "\nGene: $gene_str\tProject: $project_str";
			system("echo \"$header\" >> $error_file");
			
			# Start analysis
			my $analysis_file = "$results_path/$gene-$project-analysis.tsv";
			my $command = "../get_gene_info.pl --gene=$gene --project=$project -i $data -o $analysis_file 2>> $error_file";
			system($command);
			
			print STDERR "Done\n";
			
			
			###########################
			#	COUNTING
			###########################
			
			print STDERR "\t\tCounting...";
			
			my $count_file = "$results_path/$gene-$project-count.tsv.uncleaned";
			
			# Print info
			my $command = "head -n 1 $analysis_file > $count_file";
			system($command);
			
			# Print header fields
			$header = `grep MUTATION < $analysis_file | cut -f 4,5,6`;
			chomp $header;
			$header = "MUTATION_COUNT\t".$header;
			system("echo \"$header\" | cat >> $count_file");
			
			# Make the actual counting
			$command = "tail -n +3 $analysis_file | cut -f 4,5,6 | sort -h | uniq -c >> $count_file";
			system($command);
			
			print STDERR "Done\n";
			
			###########################
			#	FILE CLEANUP
			###########################
			
			print STDERR "\t\tCleanup...";
			
			my $count = STDIN;
			open_input($count, "$count_file");
			
			my $clean_count = STDOUT;
			$count_file =~ /(.*?tsv)/;
			open_output($clean_count, "$1");
			
			while(my $line = <$count>)
			{
				# Clean trailing newlines
				chomp $line;
				
				unless ($line =~ /[A-Z]/)
				{
					# Remove leading spaces
					$line =~ s/^ +//;
					# Change inner spaces for tabs
					$line =~ s/ /\t/;
				}
				
				print $clean_count "$line\n";
			}
			system("rm $count_file");
			close $count;	close $clean_count;
			
			print STDERR "Done\n";
			print STDERR "\tDone $gene_str\n";
		}
		
		print STDERR "Done $project_str\n";
	}

	print STDERR "All done\n";

#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


#	===========
#	Subroutines
#	===========

sub open_input
# Prints given message and opens input file
# Exit with error if it fails to open the file
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
# Prints given message and opens file for output
# Exit with error if it fails to open the file
{
	my $file_handler = shift;
	my $file_name = shift;
	my $message = shift;

	# Open output file
	print $message;
	open ($file_handler, ">", $file_name)
		or die "Can't open $file_name for output : $!";
}#-----------------------------------------------------------
