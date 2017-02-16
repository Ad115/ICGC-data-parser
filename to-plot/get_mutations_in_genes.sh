#! /usr/bin/sh
for i in `ls -1 | grep ENSG | grep locations.tsv`; do echo `tail -n +3 $i | wc -l`; done 
