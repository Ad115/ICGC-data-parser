#! /usr/bin/env python3
'Count mutations per gene from a VCF file.'

import sys
import click
import vcf
import re
from collections import defaultdict, namedtuple, Counter

# Auxiliary structure
Gene = namedtuple('Gene', ['gene_symbol', 'gene_affected'])    
# ---

def subfield_parser(info, sep='|'):
    'From the description of the field, get a parser for the subfields.'
    # Get the field id
    field_id = info.id
    
    # Get the subfields names
    subfields_str = re.findall("\(subfields: (.*?)\)", info.desc)[0]
    subfields = subfields_str.split(sep)
    
    # Create the structure
    field_struct = namedtuple(field_id, subfields)
    
    # Create parser
    def parse(record):
        # Parse the field items
        return [field_struct(*item.split(sep)) 
                    for item in record.INFO[field_id]
                       if item]
    
    parse.field_id = info.id
    parse.subfields = subfields
    return parse
# ---

def mutations_per_gene(ssm_reader):
    'Return the count of mutations per gene.'
    mutations_counter = Counter()
    # Generate parsers for the subfields
    CONSEQUENCE = subfield_parser(ssm_reader.infos['CONSEQUENCE'])
    # Accumulate mutations
    for record in ssm_reader:
            genes_affected = {Gene(item.gene_symbol, item.gene_affected) 
                                  for item in CONSEQUENCE(record)}
            mutations_counter.update(genes_affected)
            
    return mutations_counter
# ---

def count_from_file(file):
    'Count the mutations per gene from the SSM file.'
    # Open the file
    ssm_reader = vcf.Reader(file)
    mutations_count = mutations_per_gene(ssm_reader)   
    
    return mutations_count
# ---


# Command line interface
@click.command()
@click.option('--input', '-i', help='File to read from.')
@click.option('--output', '-o', help='File to write output.')
def cli_entry_point(input, output):
    'Count the mutations from the input VCF file by gene.'
    # Get the output file
    in_ = open(input) if input else sys.stdin
    out = open(output) if output else sys.stdout
    
    mutations_count = count_from_file(in_)    
    # Print the results
    for gene,mutations in mutations_count.most_common():
        print(f'{gene.gene_symbol}({gene.gene_affected}): {mutations}', file=out)



if __name__ == '__main__':
    # Command line interface
    cli_entry_point()