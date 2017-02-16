#! /bin/bash

#Run through the bash shell
#$ -S /bin/bash
# Your job name
#$ -N first_job
# Use current working directory
#$ -cwd
# If modules are needed, source modules environment (Do not delete the next line):
. /etc/profile.d/modules.sh
#$ -t 1-2

progDirs=("$HOME/ICGC-data-parser" "$PROGRAMS_PATH")
echo "dirs: ${progDirs[@]}"
echo "Current: $SGE_TASK_ID: ${progDirs[$SGE_TASK_ID-1]}"
time ${progDirs[${SGE_TASK_ID}-1]}/filter_gene_project.pl -g TP53 -p BRCA-EU -i $ICGC_DATA -o $RESULTS_PATH/TP53_BRCA-EU_$SGE_TASK_ID.tsv

