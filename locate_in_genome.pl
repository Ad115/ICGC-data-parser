#! /usr/bin/perl

my $doc_str = <<END;

Usage: ./locate_in_genome.pl [--in=<file>] [--out=<outfile>] [--help]

============================
 Locate mutations in genome
============================

With the output from filter_gene_project.pl queries the Ensembl database about
the location of each mutation in the genome, assigning one of the labels INTERGENIC,
EXONIC:#, NON-CODING-EXONIC, INTRONIC to each of them, where the '#' stands for
the *phase* understood as the position in the codon, and can be 0, 1 or 2.

Command-line arguments:

	-i, --in
		Name of the input file.
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
	my $in_name = ''; my $out_name = ''; my $help;
	GetOptions(
		'i|in=s' => \$in_name,
		'o|out=s' => \$out_name,
		'h|help' => \$help
		);


	my $in = STDIN;# Open input file
	if($in_name)  { open_input($in, $in_name); }

	my $out = STDOUT; # Open output file
	if ($out_name)  { open_output($out, $out_name); }

	# Check if user asked for help
	if($help) { print_and_exit($doc_str); }

## DATA INITIALIZATION

    # Get header and pass it directly to output
    my $header = <$in>;
    print $out "$header"; # --->

    # Get project from the header
    my $project = undef;
    unless ($header =~ /All projects/)
    {
        $header =~ /Project: ([A-Z-]*)/;
        $project = $1;
    }

    # Get important columns
    my %fields = get_fields_from($in,
								'MUTATION_ID', # Mutation ID
                                'MUTATION', # Description of the mutation
								'POSITION', # Position of the mutation in the genome
                                'AFFECTED_GENES', # Genes affected by the mutation (predicted)
                                'PROJECT(S)' # Project(s) in wich mutation appears
								);

    my @output_fields = ('MUTATION_ID', 'POSITION', 'MUTATION','RELATIVE_POSITION', 'OVERLAPPED_GENES', 'AFFECTED_GENES');
    push( @output_fields, 'PROJECT(S)') unless ($project);
    print $out join("\t", @output_fields) ."\n"; # --->

## WEB DATA INITIALIZATION

    # Initialize a connection to the db.
    my $connection = ensembldb_connect();
    my $slice_adaptor = $connection -> get_adaptor( 'Human', 'Core', 'Slice' );
	my %gene_name = ();# Associates gene's stable_id -> display_label

## MAIN SEARCH
    while(my @line = get_tsv_fields($in)) # Get mutation by mutation
    {
        ## INITIALIZE MUTATION DATA
            my %mutation = ();

            # Get mutation ID and project if a project wasn't specified
            $mutation{'MUTATION_ID'} = $line[ $fields{'MUTATION_ID'} ];
            $mutation{'MUTATION'} = $line[ $fields{'MUTATION'} ];
            $mutation{'AFFECTED_GENES'} = $line[ $fields{'AFFECTED_GENES'} ];
            $mutation{'PROJECT(S)'} = $line[ $fields{'PROJECT(S)'} ] unless ($project);
            $mutation{'RELATIVE_POSITION'} = 'UNIDENTIFIED';
            $mutation{'OVERLAPPED_GENES'} = '';

            # Get chromosome and position in chromosome
            $line[ $fields{'POSITION'} ] =~ /Chrom([0-9]*)\(([0-9]*)\)/;
            $mutation{'CHROM'} = $1;
            $mutation{'POS_37'} = $2;

            # Get the length of the mutated sequence
            $mutation{'MUTATION'} =~ /([A-Z]*)>[A-Z]*/;
            my $length = length $1;

            # Convert coordinates from assembly GRCh37 to assembly GRCh38
            $mutation{'POS_38'} = @{ map_GRCh37_to_GRCh38( $mutation{'CHROM'}, $mutation{'POS_37'}, $length ) }[0];
            $mutation{'POSITION'} = "Chrom$mutation{'CHROM'}($mutation{'POS_38'})";

            # Fetch a slice from the mutation
            my $mutation_slice = fetch_slice( $mutation{'CHROM'}, $mutation{'POS_38'}, $length );

        ## CHECK IF IT IS INTERGENIC
            if ( is_intergenic($mutation_slice) )
            {
                $mutation{'RELATIVE_POSITION'} = 'INTERGENIC';
            }
            else
            # It is overlapping at least one gene
            {
                # Get overlapped genes
                $mutation{'OVERLAPPED_GENES'} = join( ',', get_overlapping_genes($mutation_slice) );

        ##  ##  ## CHECK IF IT IS INTRONIC
                    if ( is_intronic($mutation_slice) )
                    {
                        $mutation{'RELATIVE_POSITION'} = 'INTRONIC';
                    }
                    else
                    {
        ##  ##  ##  ##  CHECK IF IT IS EXONIC ON NON-CODING-EXONIC
                        my $phase = get_phase($mutation_slice);

                        if ( $phase == -1 )
                        {
                            $mutation{'RELATIVE_POSITION'} = 'NON-CODING-EXONIC';
                        }
                        else
                        {
                            $mutation{'RELATIVE_POSITION'} = "EXONIC:$phase";
                        }
                    }
            }

        print_fields(\%mutation, \@output_fields); # --->
    }

#===============>> END OF MAIN ROUTINE <<=====================

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

sub get_tsv_line
# Get a line from a TSV file
{
	my $file = shift;

	# Skip comments
	my $line;
	do	{ $line = <$file>; }
	while($line =~ /^#.*/);

	chomp $line;
    return $line;
}#-----------------------------------------------------------

sub get_tsv_fields
# Get a line from a TSV file splitted in an array
{
	my $file = shift;

    my @line = split( "\t", get_tsv_line($file) );
    return @line;
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

	return -1;
}#-----------------------------------------------------------

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

	print STDERR "$name: (" . join(',', @array) . ")\n";
}#-----------------------------------------------------------

sub print_hash
# Prints the content of the passed hash
{
	my %hash = %{shift()};
	my $name = shift;

	print STDERR "$name: ".Dumper \%hash;
}#-----------------------------------------------------------

sub uniq
# Remove repeated entries from array
{
	my @array = @{shift()};
	my %seen;

	return grep !($seen{$_}++), @array;
}#-----------------------------------------------------------

sub any
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $key = shift;
	my @array = @{shift()};

	foreach my $i (@array)
	{
		if ($key eq $i)
		{
			return 1;
		}
	}
	return 0;
}#-----------------------------------------------------------

sub map_GRCh37_to_GRCh38
# Maps a coordinate in the reference assembly GRCh37 to GRCh38
{
	my $chromosome = shift;
	my $position = shift;
	my $length = shift;

	my $begin_slice = $position;

	my $slice = @{ fetch_GRCh38_slice_from_GRCh37_region($chromosome, $begin_slice, $length) }[0];

	my @return = ();
	eval { @return = ($slice->start(), $slice->end()); };
	if ($@)
	{
		warn $@;
		return (-1, -1);
	}
	return \@return;
}#-----------------------------------------------------------

sub contains
# Gets a scalar and an array as arguments, if the scalar is in the array returns 1
{
	my $start = shift;
	my $end = shift;
	my $mapped_pos_in_chrom = shift;

	if ($start < $mapped_pos_in_chrom && $mapped_pos_in_chrom < $end)
	{
		return $mapped_pos_in_chrom - $start + 1;
	}

	else { return undef; }
}#-----------------------------------------------------------

sub fetch_GRCh38_slice_from_GRCh37_region
# Fetches a slice in the GRCh38 assembly from GRCh37 coordinates
{
	my $chromosome = shift;
	my $begin = shift;
	my $length = shift;

    my $end = $begin + ($length - 1);

	# Fetch slice in the GRCh37 assembly
	my $GRCh37_slice = $slice_adaptor->fetch_by_region( 'chromosome', $chromosome, $begin, $end, '1', 'GRCh37' );

	# Make a projection onto the GRCh38 coordinates
	my $projection = $GRCh37_slice->project('chromosome', 'GRCh38');
	my @slices = ();

	foreach my $segment ( @{$projection} )
	{
      my $slice = $segment->to_Slice();
	  push @slices, $slice;
	}

	return \@slices;
}#-----------------------------------------------------------

sub get_fields_from
# returns a dictionary with the positions of the fields
{
	my $in = shift; # The input file
	my @fields = ();	# The fields to search
	while (my $field = shift) { push @fields, $field; }

	# Get the fields
	my @fields = get_tsv_fields($in);

	# Get the column position of the searched fields
	my %fields = ();
	foreach my $field (@fields)
	{
		$fields{$field} = get_col_number($field, \@fields);
	}

	return %fields;
}#-----------------------------------------------------------

sub search_patterns
# Usage: search_patterns(\LIST, STRING)
# Retuns the elements in LIST that are a substring in STRING
{
	my @patterns = @{ shift() };
	my $string = shift;

	my @matches = ();
	foreach my $pattern (@patterns)
	{
		my $re = qr/$pattern/;
		push( @matches, $pattern ) if ($string =~ /$re/);
	}

	return @matches;
}#-----------------------------------------------------------

sub get_stable_ids
# Usage: get_stable_ids(\@features);
# Retuns the list with the stable id of the features in the array
{
	my @features = @{shift()};

	my @stable_ids = ();
	foreach my $feature (@features)
	{
		push( @stable_ids, $feature -> stable_id() );
	}

	return @stable_ids;
}#-----------------------------------------------------------

sub read_line_as_hash
# Retuns the hash with the header associaciated with its respective information
{
	my @line = @{shift()};
	my %headers = %{shift()};

	my %line = ();
	foreach my $header (keys %headers)
	{
		$line{ $header } = $line[ $headers{$header} ];
	}

	return \%line;
}#-----------------------------------------------------------

sub fetch_slice
# Fetches a slice from it's coordinates and length
{
	my $chromosome = shift;
	my $begin = shift;
	my $length = shift;

    # Fetch slice
    my $end = $begin + ($length - 1);
	return $slice_adaptor -> fetch_by_region( 'chromosome', $chromosome, $begin, $end );
}#-----------------------------------------------------------

sub is_intergenic
# Checks whether a slice is intergenic or not (is intergenic if it doesn't overlap any gene)
{
	my $slice = shift;

    my @overlapping = @{ $slice -> get_all_Genes() };
    return ($#overlapping) ? 1:0;
}#-----------------------------------------------------------

sub get_overlapping_genes
# Returns a list of all genes overlapping the slice
{
	my $slice = shift;

    @overlapping = @{ $slice -> get_all_Genes() };
    return get_print_data(\@overlapping);
}#-----------------------------------------------------------

sub is_intronic
# Checks whether a slice is intronic or not
{
	my $slice = shift;

    my @overlapping = @{ $slice -> get_all_Exons() };

    return (@overlapping) ? 0:1;
}#-----------------------------------------------------------

sub get_phase
# Gets the phase of an exonic mutation
{
	my $slice = shift;

    my @exons = @{ $slice -> get_all_Exons() };
    my $slice_start = $slice -> start();
    my $mutation_phase = undef;

    foreach my $exon (@exons)
    {
        if ( slice_in_exon($slice, $exon) )
        {
            $exon_phase = $exon -> phase();
            $exon_start = $exon -> seq_region_start();
            $mutation_phase = ( $exon_phase + ($slice_start - $exon_start) ) % 3;
            $mutation_phase = -1 if ($exon_phase == -1);

            last;
        }
    }

    return $mutation_phase;
}#-----------------------------------------------------------

sub slice_in_exon
# Checks whether a slice is intergenic or not (is intergenic if it doesn't overlap any gene)
{
	my $slice = shift;
    my $exon = shift;

    my @slice = ($slice->start(), $slice->end());
    my @exon = ($exon->seq_region_start(), $exon->seq_region_end());

    return ($slice[0] <= $exon[0]) ? ($slice[1] >= $exon[0]) : ($slice[0] <= $exon[1]);
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
}#-----------------------------------------------------------

sub get_print_data
{
	my @genes = @{ shift() };
	
	my @gene_data = get_stable_ids(\@genes);
	foreach my $gene (@gene_data)
	{
		#Get common name if not provided
		$display_label = get_display_label($gene);
		$gene = "$gene($display_label)";
	}
	
	return @gene_data;
}#-----------------------------------------------------------

sub get_display_label()
# Remove repeated entries from array
{
	my $gene = shift;
	
	unless ($gene_name{$gene})
	{
		$gene_name{$gene} = $connection 
								-> get_adaptor( 'Human', 'Core', 'Gene' )
								-> fetch_by_stable_id($gene)
								-> external_name();
	}
	
	return $gene_name{$gene};
}#-----------------------------------------------------------

