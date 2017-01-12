#! /usr/bin/perl

my @genes = ('TP53', 'LRP1B', 'BRAF', 'RYR2', 'KMT2C');
my @projects = ('', 'BRCA-US', 'GBM-US');

my $data = "../../data_release_22/ssm.aggregated.vcf";
my $results_path = "../../results";

foreach my $project (@projects)
{
	foreach my $gene (@genes)
	{
		my $command = "../get_gene_info.pl -g $gene -i $data -o $results_path/$gene-$project.tsv -p $project  2> $results_path/$gene-$project.err";
		system($command);
	}
}

