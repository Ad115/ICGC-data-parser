#! /usr/bin/perl

my $doc_str = <<END;

Usage: ./get_gene_info.pl [--gene=<gene name>] [--project=<ICGC project name>] [--in=<vcffile>] [--out=<outfile>] [--help]

===============
 Get gene info
===============

Searches through input file for mutations related to the given gene and the given project.

	-g, --gene
		Gene name, in display form.

	-p, --project
		Project name.
		If present, shows only mutations found in that project.

	-i, --in, --vcf
		Name of the input VCF file.
		If not present, input from standard input.

	-o, --out
		Name of the output file.
		If not present output to standard output.

	-h, --help
		Show this text and exit.

Author: Andrés García García @ Oct 2016.

END


use Getopt::Long; # To parse command-line arguments
use Bio::EnsEMBL::Registry; # From the Ensembl API, allows to conect to the db.
use Data::Dumper; # To preety print hashes easily
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 1;

#===============>> BEGINNING OF MAIN ROUTINE <<=====================

## INITIALIZATION

	# Declare variables to hold command-line arguments
	my $inputfile_name = ''; my $out_name = '';
	my $gene = ''; my $project = '';
	my $help;
	GetOptions(
		'i|in|vcf=s' => \$inputfile_name,
		'o|out=s' => \$out_name,
		'g|gene=s' => \$gene,
		'p|project=s' => \$project,
		'h|help' => \$help
		);


	my $inputfile = STDIN;# Open input file
	if($inputfile_name)  { open_input($inputfile, $inputfile_name); }


	my $out = STDOUT; # Open output file
	if ($out_name)  { open_output($out, $out_name); }

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }


## LOCAL DATA INITIALIZATION

	#Get project
	$project = '' if (lc $project eq 'all');
	my $project_re = undef;
	$project_re = qr/$project/ if ($project);

	# Get header
	my %header = get_fields_from($inputfile,
								'ID', # Mutation ID
								'CHROM', # The column that specifies chromosome number
								'POS', # Position in chromosome
								'REF', # Sequence or base in the reference, this is the one we care to compare
								'ALT', # Alternate sequence. This is found instead of the reference
                                'INFO' # Other information of the gene
								);

## WEB DATA INITIALIZATION

	# Initialize a connection to the db.
	$connection = ensembldb_connect();
	
	# Get gene's stable id	
	my %gene_name = (); # To store an association of gene's stable_id -> display_label
	my $gene_id = undef;
	# Get the gene id if user didn't provided it
	if ($gene)
	{
		if ($gene =~ /ENSG[0-9]{11}/) # User provided stable ID
		{
			$gene_id = $gene;
			# Get common name
			$gene = $connection -> get_adaptor( 'Human', 'Core', 'Gene' )
								-> fetch_by_stable_id($gene)
								-> external_name();
			$gene_name{$gene_id} = $gene;
		}
		elsif (lc $gene eq 'all') # User wants to search in all genes
		{
			$gene = '';
		}
		else # User provided the display label
		{ 
			$gene_id = get_gene_id($gene); 
			$gene_name{$gene_id} = $gene;
		}
	}

	my $gene_str = ($gene) ? $gene : "All genes";
	$gene_str = ($gene_id) ? "$gene_str($gene_id)" : "$gene_str";
	my $gene_re = ($gene) ? qr/$gene_id/ : qr/.*/;

	my $project_str = ($project) ? $project : "All projects";
	my $project_re = ($project) ? qr/$project/ : qr/.*/;

	print "# Project: $project_str\tGene: $gene_str\n";


	my @output_line_fields = ('MUTATION_ID', 'POSITION', 'MUTATION', 'AFFECTED_GENES', 'PROJ_AFFECTED_DONORS', 'PROJ_TESTED_DONORS', 'PROJ_MUTATION_FREQUENCY');
	unless($project) { @output_line_fields = ('MUTATION_ID', 'POSITION', 'MUTATION', 'AFFECTED_GENES', 'TOTAL_AFFECTED_DONORS', 'TOTAL_TESTED_DONORS', 'TOTAL_MUTATION_FREQUENCY', 'PROJECT(S)'); }
	print join( "\t", @output_line_fields)."\n";

## MAIN QUERY
	
	while(my $line = get_vcf_line($inputfile)) # Get mutation by mutation
	{
		# Check for specified gene
		if ($line =~ $gene_re)
		{
			# Check for specified project
			if (!$project or ($project and $line =~ $project_re))
			{				
                # Get affected genes
                my @affected_genes = @{ get_genes($line) };
                my $affected_genes = join( ',', @affected_genes );
				
				# Split line in fields
				my @line = split( /\t/, $line );

				# If project was specified
				if ($project)
				{
					# Get occurrence data
					$line =~ /OCCURRENCE=(.*?);/;
					my @occurrences = split( /,/ , $1);

					foreach my $occurrence (@occurrences)
					{
						if ($occurrence =~ $project_re)
						{
							my @occurrence = split( /\|/, $occurrence);
							my %mutation = (
								'MUTATION_ID' => $line[$header{'ID'}],
								'POSITION' => "Chrom$line[$header{'CHROM'}]($line[$header{'POS'}])",
								'MUTATION' => "$line[$header{'REF'}]>$line[$header{'ALT'}]",
								'AFFECTED_GENES' => $affected_genes,
								'PROJ_AFFECTED_DONORS' => "$occurrence[1]",
								'PROJ_TESTED_DONORS' => "$occurrence[2]",
								'PROJ_MUTATION_FREQUENCY' => "$occurrence[3]"
								);

							print_fields(\%mutation, ['MUTATION_ID', 'POSITION', 'MUTATION', 'AFFECTED_GENES', 'PROJ_AFFECTED_DONORS', 'PROJ_TESTED_DONORS', 'PROJ_MUTATION_FREQUENCY']);
						}
					}
				}
				else
				{
					# Get occurrence data
					$line =~ /OCCURRENCE=(.*?);(.*)/;
					my $total_occurrence = $2;

					my @occurrences = split /,/,  $1;
					my @projects = ();
					foreach my $occurrence (@occurrences)
					{
						$occurrence =~ /^([A-Z-]*)\|/;
						push @projects, $1;
					}

					my @line = split( /\t/, $line );
					my @total_occurrence = split( /;/, $total_occurrence );

					my %mutation = (
								'MUTATION_ID' => $line[$header{'ID'}],
								'POSITION' => "Chrom$line[$header{'CHROM'}]($line[$header{'POS'}])",
								'MUTATION' => "$line[$header{'REF'}]>$line[$header{'ALT'}]",
								'AFFECTED_GENES' => $affected_genes
								);
					$total_occurrence =~ /affected_donors=([0-9]*)/;
					$mutation{'TOTAL_AFFECTED_DONORS'} = $1;
					$total_occurrence =~ /tested_donors=([0-9]*)/;
					$mutation{'TOTAL_TESTED_DONORS'} = $1;
					$mutation{'TOTAL_MUTATION_FREQUENCY'} = $mutation{'TOTAL_AFFECTED_DONORS'} / $mutation{'TOTAL_TESTED_DONORS'};
					$mutation{'PROJECT(S)'} = join ",", @projects;

					print_fields(\%mutation, ['MUTATION_ID', 'POSITION', 'MUTATION', 'AFFECTED_GENES', 'TOTAL_AFFECTED_DONORS', 'TOTAL_TESTED_DONORS', 'TOTAL_MUTATION_FREQUENCY', 'PROJECT(S)']);
				}
			}
		}
	}


#===============>> END OF MAIN ROUTINE <<=====================


#-------------------------------------------------------------


#	===========
#	Subroutines
#	===========

sub ensembldb_connect
# Initialize a connection to the db
{
  # Initialize a registry object
  my $registry = 'Bio::EnsEMBL::Registry';

  # Connect to the Ensembl database
  print STDERR "Waiting connection to database...\n";
  $registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org', # Alternatively 'useastdb.ensembl.org'
      -user => 'anonymous'
      );
  print STDERR "Connected to database\n";

  return $registry;
}#------------------------------------------------------

sub get_vcf_line
# Get a line from a VCF file
{
	my $vcffile = shift;

	# Skip comments
	my $line;
	do	{ $line = <$vcffile>; }
	while($line =~ /^##.*/);

	# Check wether you are in the headers line
	if ($line =~ /^#(.*)/) { $line = $1; }

	return $line;
}#-----------------------------------------------------------

sub get_vcf_fields
# Get a line from a VCF file splitted in fields
{
	my $vcffile = shift;

	# Skip comments
	my $line;
	do	{ $line = <$vcffile>; }
	while($line =~ /^##.*/);

	# Check wether you are in the headers line
	if ($line =~ /^#(.*)/) { $line = $1; }

	return split( /\t/, $line);
}#-----------------------------------------------------------

sub get_gene_id
# Query the database for the stable id of the given gene
{
  my $gene_name = shift;

  # Declare a gene adaptor to get the gene
  my $gene_adaptor = $connection->get_adaptor( 'Human', 'Core', 'Gene' );
  # Declare a gene handler with the given gene
  my $gene = $gene_adaptor->fetch_by_display_label($gene_name);
  unless($gene) { die "ERROR: Gene '$gene_name' not found\n"; }

  # Get the gene's EnsembleStableID
  return $gene->stable_id();
}#-------------------------------------------------------

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

sub print_and_exit
# Prints given message and exits
{
	my $message = shift;
	print $message;
	exit;
}#-----------------------------------------------------------

sub print_array
# Prints the content of the passed array
{
	my @array = @{shift()};
	my $name = shift;

	print "$name: (" . join(',', @array) . ")\n";
}#-----------------------------------------------------------

sub get_fields_from
# returns a dictionary with the positions of the fields
{
	my $inputfile = shift; # The input file
	my @fields = ();	# The fields to search
	while (my $field = shift) { push @fields, $field; }

	# Get the fields
	my @fields = get_vcf_fields($inputfile);

	# Get the column position of the searched fields
	my %fields = ();
	foreach my $field (@fields)
	{
		$fields{$field} = get_col_number($field, \@fields);
	}

	return %fields;
}#-----------------------------------------------------------

sub get_col_number
# Get the numeric position of the column whose name is given
{
	my $col_name = shift;
	my @fields = @{shift()};

	# Get the column numbers
	foreach my $i (0..$#fields)
	{
		return $i if ($col_name eq $fields[$i]);
	}

	die "Column '$colname' not found!\n!";
}#-----------------------------------------------------------

sub print_fields
# USAGE: print_fields(\%hash, \@keys)
# Print orderly the values corresponding to the given keys of the hash
# Prints in TSV format
{
	my %hash = %{shift()};
	my @keys = @{shift()};

	# Print the given fields
	foreach my $key (@keys)
	{
		print "$hash{$key}\t";
	}
	print "\n";

	return;
}#-----------------------------------------------------------

sub print_hash
# Prints the content of the passed hash
{
	my %hash = %{shift()};
	my $name = shift;

	print "$name: ".Dumper \%hash;
}#-----------------------------------------------------------

sub uniq
# Remove repeated entries from array
{
	my @array = @{shift()};
	my %seen;

	return grep !($seen{$_}++), @array;
}#-----------------------------------------------------------

sub get_genes
# Get the affected genes for the mutation
{
	my $line = shift;

	my @genes = ($line =~ /(ENSG[0-9]+)/g);
	@genes = uniq(\@genes);
	foreach my $gene (@genes)
	{
		#Get common name if not provided
		$display_label = get_display_label($gene);
		$gene = "$gene($display_label)";
	}
	
	return \@genes
}#-----------------------------------------------------------

sub get_display_label()
# Get the display label for the genes in the gene array
{
	my $gene = shift;
	
	unless ($gene_name{$gene})
	{
		eval 
		{ 
			$gene_name{$gene} = $connection 
								-> get_adaptor( 'Human', 'Core', 'Gene' )
								-> fetch_by_stable_id($gene)
								-> external_name(); 
			
		}; if ($@)
		{
			warn $@;
			$gene_name{$gene} = 'NOLABEL';
		}
	}
	
	return $gene_name{$gene};
}#-----------------------------------------------------------