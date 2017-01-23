#! /usr/bin/perl

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

	# Get the output and input directories
	my $programs_path = `echo -n \$PROGRAMS_PATH`;
	print STDERR "Programs path: $programs_path\n";
	
	my $data = `echo -n \$ICGC_DATA`;
	print STDERR "Data: $data\n";
	
	my $results_path = `echo -n \$RESULTS_PATH`;
	print STDERR "Results path: $results_path\n";

	# Get the genes and projects to analyze
	my @genes = `$programs_path/get_all_affected_genes.pl -i $data`;
	chomp @genes;
	print STDERR "Genes: ".join(',', @genes)."\n";
	# TP53(ENSG00000141510), HER2(ERBB2)(ENSG00000141736), MDM2(ENSG00000135679), BRCA1(ENSG00000012048), ATM(ENSG00000149311), CDK2(ENSG00000123374)
	my @projects = `get_all_projects.pl -i $data`;
	chomp @projects;
	print STDERR "Projects: ".join(',', @projects)."\n";

	foreach my $project (@projects)
	{
		my $project_str = ($project) ? $project : "All projects";
		print STDERR "Project: $project_str\n";

		foreach my $gene (@genes)
		{
			my $gene_str = ($gene) ? $gene : "All genes";
			print STDERR "\tGene: $gene_str\n";
			
			my $header = "Gene: $gene_str, Project: $project_str";
			print STDERR "\t==> $header <==\n";

			##########################
			#	MUTATION ANALYSIS
			##########################

			print STDERR "\t\tAnalysis(`date +%F\@%R`)...\n".
			"================================\n";

			# Start analysis
			my $analysis_file = "$results_path/$gene\_$project\_analysis.tsv";
			my $command = "$programs_path/filter_gene_project.pl --gene=$gene --project=$project -i $data -o $analysis_file";
			system($command);

			print STDERR "\t\t...Done analysis\n";


			###########################
			#	LOCATING IN GENOME
			###########################

			print STDERR "\t\tClassifying mutations(`date +%F\@%R`)...\n".
			"================================\n";

			my $classification_file = "$results_path/$gene\_$project\_locations.tsv";

			# Print info
			$command = "$programs_path/locate_in_genome.pl -i $analysis_file -o $classification_file";
			system($command);


			print STDERR "\t\tDone classifying mutations\n";


			###########################
			#	COUNTING
			###########################

			print STDERR "\t\tCounting mutations(`date +%F\@%R`)...\n".
			"================================\n";

			my $count_file = "$results_path/$gene\_$project\_locations-count.tsv";

			# Print header
			system("head $classification_file -n 1 > $count_file");
			# Actual counting
			$command = "cut -f 4 < $classification_file | tail -n +3 | sort | uniq -c | sort -g -r >> $count_file";
			system($command);

			print STDERR "\t\tDone counting mutations\n";

			###########################
			#	FILE CLEANUP
			###########################

			print STDERR "\t\tCleanup(`date +%F\@%R`)...\n".
			"================================\n";

			system("rm $analysis_file");

			print STDERR "\t\tDone cleanup\n";
			print STDERR "\tDone ==> $header <==\n";
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
