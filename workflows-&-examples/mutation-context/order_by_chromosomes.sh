#! usr/bin/env bash

# Declare a chromosomes array
CHROMOSOMES=(`seq 1 22` 'X' 'Y' 'MT')

# Get the project and gene for which the results were calculated
HEADER_PROJECT_GENE=`cat $RESULTS_PATH/*mutations-context*tsv | head -n1 | cut -f1,2`
# Get the result TSV file's schema
SCHEMA=`cat $RESULTS_PATH/*mutations-context*tsv | awk 'NR == 2 {print; exit}'`

CHROM_MUT_ANALISED=() # The count mutations (per chromosome) whose context we have
CHROM_TOTAL_MUTATIONS=() # The total count of mutations reported per chromosome

for i in ${CHROMOSOMES[@]}; do 

    # Fetch the total mutations analized for this chromosome
    CHROM_MUT_ANALISED+=(`cat $RESULTS_PATH/*mutations-context*tsv | grep "chr${i}:" | wc -l`)
    # Print the count
    echo -n "chromosome ${i} analysed:"
    echo -n ${CHROM_MUT_ANALISED[-1]}
    
    #Fetch the total mutations reported for this chromosome
    CHROM_TOTAL_MUTATIONS+=(`tail -n +14 $ICGC_DATA | cut -f1 |  grep "^${i}$" | wc -l`)
    # Print the count
    echo -n ";    chromosome ${i} reported:"
    echo ${CHROM_TOTAL_MUTATIONS[-1]}
    
    # Get the new file header and schema
    FILE="$RESULTS_PATH/mutation-context_chr$i.tsv"
    HEADER=`echo -e "$HEADER_PROJECT_GENE\tChromosome: $i\tMutations analysed successfully: ${CHROM_MUT_ANALISED[-1]}\tMutations not analysed: $(expr ${CHROM_TOTAL_MUTATIONS[-1]} - ${CHROM_MUT_ANALISED[-1]})"`
    
    # Output to file
    echo "$HEADER" > $FILE
    echo "$SCHEMA" >> $FILE
    cat $RESULTS_PATH/*mutations-context*tsv | grep "chr${i}:" >> $FILE

done;
