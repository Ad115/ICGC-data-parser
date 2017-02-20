#! /bin/bash

#Run through the bash shell
#$ -S /bin/bash
# Your job name
#$ -N JOBNAME
# Use current working directory
#$ -cwd
# If modules are needed, source modules environment (Do not delete the next line):
. /etc/profile.d/modules.sh
#$ -t 1-NJOBS

echo "Hi! I am task number: $SGE_TASK_ID"
