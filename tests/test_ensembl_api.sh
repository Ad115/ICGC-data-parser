#! /bin/bash

# ==========================================
#   Test the Ensembl Perl API availability
# ==========================================
#
# Deceptively simple test suite for the Ensembl Perl API.
# Tries to call the programs in the ensembl_API folder and checks exit status.

# Initialize a counter for the succesfull runs
successes=0; fails=0

# Declare the calls array
declare -a calls
# Declare call to get_gene_sequences.pl
calls[0]="../ensembl_API/get_gene_sequences.pl -s Homo_sapiens -g TP53,ENSG00000141736 -l200"
# Declare call to get_sequence.pl
calls[1]="../ensembl_API/get_sequence.pl -s zebrafish -c17 -p 48657634-48657734"
# Declare call to list_all_databases.pl
calls[2]="../ensembl_API/list_all_databases.pl"

# ------------------------------------------------------------
for call in "${calls[@]}"; do
    # Execute program
    printf "Now executing...\n %s\n" "$call"

    if $call; then
        echo "...Succesfull run! :D"
        let successes++
    else
        echo "...OOOPS! Something went wrong! D:"
        let fails++
    fi
done
# ------------------------------------------------------------

echo "Finished tests with a total of $successes successes and $fails fails"

# End of the tests
