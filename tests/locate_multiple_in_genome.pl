#! /usr/bin/perl


my $doc_str = <<END;

Usage: ./locate_multiple_in_genome.pl [--genes=<g1,g2,...>] [--projects=<p1,p2,...>] [-gf <genes.list>] [-pf <proyects.list>][--help]

============================
 Locate multiple in genome
============================

Script to run locate_in_genome.pl with multiple genes and projects.

Common genes: TP53(ENSG00000141510), ERBB2(HER2)(ENSG00000141736), MDM2(ENSG00000135679), BRCA1(ENSG00000012048), ATM(ENSG00000149311), CDK2(ENSG00000123374).
Common projects: BRCA-EU, GBM-EU.

Command-line arguments:

	-g, --gene, --genes
		Genes to analize. Is a comma separated list.
		May be a common name or the display ID.
		An empty gene or the gene 'all' stands for analizing all genes

	-p, --project, --projects
		Projects to analize. Is a comma separated list.
		An empty project or the project 'all' stands for analizing all projects
		
	-gf, --gene_file
		Specifies a file from which to read the genes to analyse.
		
	-pf --project_file
		Specifies a file from which to read the projects to analyse.

	-h, --help
		Show this text and exit.

Author: Andrés García García @ Oct 2016.

END


use Getopt::Long; # To parse command-line arguments

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Declare variables to hold command-line arguments
	my $genes = ''; my $projects = '';
	my $genes_file = ''; my $projects_file = '';
	my $help;
	GetOptions(
		'g|gene|genes=s' => \$genes,
		'p|project|projects=s' => \$projects,
		'gf|gene_file=s' => \$genes_file,
		'pf|project_file=s' => \$projects_file,
		'h|help' => \$help
		);

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }
	
	print $genes."\n";
	print $projects."\n";
	my @genes = split( ',', $genes );
	my @projects = split( ',', $projects );
	
	if ($genes_file)	
	{ 
		push @genes, grep(chomp, `cat $genes_file`); 
		@genes = uniq(\@genes);
		
	}
	if ($projects_file)
	{ 
		push @projects, grep(chomp, `cat $projects_file`); 
		@projects = uniq(\@projects);
		
	}
	
	print STDERR "Genes: ".join(',', @genes)."\n";
	print STDERR "Projects: ".join(',', @projects)."\n";

	# Get the output and input directories
	my $programs_path = `echo -n \$PROGRAMS_PATH`;
	print STDERR "Programs path: $programs_path\n";
	
	my $data = `echo -n \$ICGC_DATA`;
	print STDERR "Data: $data\n";
	
	my $results_path = `echo -n \$RESULTS_PATH`;
	print STDERR "Results path: $results_path\n";
	
## MAIN LOOP
	
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

			my $date = date("%F\@%R");
			print STDERR "\t\tAnalysis($date)...\n".
			"================================\n";

			# Start analysis
			my $analysis_file = "$results_path/$gene\_$project\_analysis.tsv";
			my $command = "$programs_path/filter_gene_project.pl --gene=$gene --project=$project -i $data -o $analysis_file";
			system($command);

			print STDERR "\t\t...Done analysis\n";


			###########################
			#	LOCATING IN GENOME
			###########################

			$date = date("%F\@%R");
			print STDERR "\t\tClassifying mutations($date)...\n".
			"================================\n";

			my $classification_file = "$results_path/$gene\_$project\_locations.tsv";

			# Print info
			$command = "$programs_path/locate_in_genome.pl -i $analysis_file -o $classification_file";
			system($command);


			print STDERR "\t\tDone classifying mutations\n";


			###########################
			#	COUNTING
			###########################

			$date = date("%F\@%R");
			print STDERR "\t\tCounting mutations($date)...\n".
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

			$date = date("%F\@%R");
			print STDERR "\t\tCleanup($date)...\n".
			"================================\n";

			system("rm $analysis_file");

			print STDERR "\t\tDone cleanup\n";
			print STDERR "\tDone ==> $header <==\n";
		}

		print STDERR "Done $project_str\n";
	}

	$date = date("%F\@%R");
	print STDERR "All done($date)\n";

#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


#	===========
#	Subroutines
#	===========

sub uniq
# Remove repeated entries from array
{
	my @array = @{shift()};
	my %seen;

	return grep !($seen{$_}++), @array;
}#-----------------------------------------------------------

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
}#-----------------------------------------------------------

sub date
# Prints given message and exits
{
	my $format = shift;
	
	my $date = `date +$format`;
	chomp $date;
	return $date;
}#-----------------------------------------------------------
