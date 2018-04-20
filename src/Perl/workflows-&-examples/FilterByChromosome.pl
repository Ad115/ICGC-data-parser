#! /usr/bin/env perl 
 
use ICGC_Data_Parser::SSM_Parser qw(:parse);
use ICGC_Data_Parser::Tools qw(:general_io :debug);

parse_SSM_file(
        # Context information
        {
            # Raw command-line options
            RAW_OPTIONS =>  \@ARGV,
            
            # Format strings for the expected command-line options (other than in, out and help)
            EXPECTED_OPTIONS   =>  [ 'chrom|c=s' ],
            
        },
        
        # Actions
        {
            # At every line
            MATCH => sub {  
                        # Fetch the context
                        my $context = shift();
                        
                        # Fetch the chromosome the user asked for
                        my $chrom = $context->{OPTIONS}{chrom};
                        
                        # Fetch mutation
                        my %mutation = %{ $context->{MUTATION} };
                        
                        # If the chromosome is the one looked for, pass it directly to output
                        if ( $mutation{CHROM} eq $chrom ) {
                            # Fetch output file
                            my $output = $context->{OUTPUT};
                            
                            # Print the line
                            print $output $context->{LINE};
                        }
                
                    }
        } # --- ACTIONS
); # --- parse_SSM_file
 
