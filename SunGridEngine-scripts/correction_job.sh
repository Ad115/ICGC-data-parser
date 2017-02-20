#! /bin/bash

#Run through the bash shell
#$ -S /bin/bash
# Join STDOUT & STDERR
#$ -j yes
# Use current working directory
#$ -cwd
# If modules are needed, source modules environment (Do not delete the next line):
. /etc/profile.d/modules.sh
# Name the job array
#$ -N each_BRCA-EU_correction1400-3300
# Use as many jobs as needed
#$ -t 1400-3300

GENES_FILE=all_affected_genes.list
GENE=$(awk "NR==$SGE_TASK_ID" $GENES_FILE)
PROJECT=BRCA-EU

# Analysis...
ANALYSIS_FILE=$RESULTS_PATH/${GENE}_$PROJECT.analysis.tsv
LOCATIONS_FILE=$RESULTS_PATH/${GENE}_$PROJECT.locations.tsv
if true; then
	echo "Now doing analysis: $ANALYSIS_FILE @ $(date +%F.%R)"
	$PROGRAMS_PATH/filter_gene_project.pl -g $GENE -p $PROJECT -i $ICGC_DATA -o $ANALYSIS_FILE
fi

# Locating...
if true; then
	echo "Now locating mutations in genome: $LOCATIONS_FILE @ $(date +%F.%R)"
	$PROGRAMS_PATH/locate_in_genome.pl -i $ANALYSIS_FILE -o $LOCATIONS_FILE
fi

# Counting...
COUNT_FILE=$RESULTS_PATH/${GENE}_$PROJECT.locations_count.tsv
if true; then
	head $LOCATIONS_FILE -n 1 > $COUNT_FILE; cut -f 4 < $LOCATIONS_FILE | tail -n +3 | sort | uniq -c | sort -g -r >> $COUNT_FILE
fi

# Cleaning up...
[ -f $ANALYSIS_FILE ] && { rm $ANALYSIS_FILE }

echo "Done: gene $GENE, project $PROJECT @ $(date +%F.%R)"
