#! /usr/bin/env perl 
 
use ICGC_Data_Parser::SSM_Parser qw(:parse);
use ICGC_Data_Parser::Tools qw(:general_io :debug);

parse_SSM_file(
        # Context information
        {
            RAW_OPTIONS =>  \@ARGV
        },
        
        # Actions
        {
            # At every line
            MATCH => sub {  
                        # Fetch the context
                        my $context = shift();
                        
                        # Create a chromosome list if not created yet
                        $context->{CHROMOSOMES} //= {};
                        
                        # Parse the mutation
                        my %mutation = %{ $context->{MUTATION} };
                        
                        # Save the chromosome
                        $context->{CHROMOSOMES}{ $mutation{CHROM} }++;
                
                    },
            
            # At the end of the file
            END =>  sub {
                        # Fetch the context
                        my $context = shift();
                        
                        my $output = $context->{OUTPUT};
                        my $chromosomes = $context->{CHROMOSOMES};
                        
                        # Display the distribution
                        foreach my $chrom (sort keys %$chromosomes) {
                            print $output "Mutations in chromosome $chrom:   $chromosomes->{$chrom}\n";
                        }
                    }
        } # --- ACTIONS
); # --- parse_SSM_file
