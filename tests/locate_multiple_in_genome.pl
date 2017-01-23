#! /usr/bin/perl

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

	my @genes = ('', 'BRCA1', 'ATM', 'CDK2');
	# TP53(ENSG00000141510), HER2(ERBB2)(ENSG00000141736), MDM2(ENSG00000135679), BRCA1(ENSG00000012048), ATM(ENSG00000149311), CDK2(ENSG00000123374)
	my @projects = ('');

	my $programs_path = "~/Programming_pc/Bioinformatica/ICGC/ICGC-data-parser";
	my $data = "~/Programming_pc/Bioinformatica/ICGC/data_release_22/ssm.aggregated.vcf";
	my $results_path = "~/Programming_pc/Bioinformatica/ICGC/results";
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

			print STDERR "\t\tAnalysis...\n";

			my $header = "\nGene: $gene_str\tProject: $project_str";
			system("echo \"$header\" >> $error_file");

			# Start analysis
			my $analysis_file = "$results_path/$gene.$project.analysis.tsv";
			my $command = "$programs_path/filter_gene_\\&_project.pl --gene=$gene --project=$project -i $data -o $analysis_file >> $error_file";
			system($command);

			print STDERR "Done\n";


			###########################
			#	LOCATING IN GENOME
			###########################

			print STDERR "\t\tClasifying mutations...";

			my $classification_file = "$results_path/$gene.$project.locations.tsv";

			# Print info
			$command = "$programs_path/locate_in_genome.pl -i $analysis_file -o $classification_file >> error_file";
			system($command);


			print STDERR "Done\n";


			###########################
			#	COUNTING
			###########################

			print STDERR "\t\tCounting mutations...";

			my $count_file = "$results_path/$gene.$project.locations-count.tsv";

			# Print header
			system("head $classification_file -n 1 > $count_file");
			# Actual counting
			$command = "cut -f 4 < $classification_file | tail -n +3 | sort | uniq -c | sort -g -r >> $count_file";
			system($command);

			print STDERR "Done\n";

			###########################
			#	FILE CLEANUP
			###########################

			print STDERR "\t\tCleanup...";

			system("rm $analysis_file");

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
