#! /usr/bin/env python3
"""
Transform the data in the ICGC mutations VCF file from the GRCh38 to the GRch37 assembly.
"""

import click
import vcf
import sys

from src.Python.ICGC_data_parser import AssemblyMapper, SSM_Reader


# Command line interface
@click.command()
@click.argument('input')
@click.option('--output', '-o', help='VCF file to write output.')
def main(input, output):
    """Map an ICGC mutations VCF file from assembly GRCh37 to GRCh38."""
    
    # --- Open the mutations file
    mutations = SSM_Reader(filename=input)

    # --- Instantiate mapper 
    mapper = AssemblyMapper(from_assembly='GRCh37', 
                            to_assembly='GRCh38')

    # --- Open the mapped file (coordinates in GRCh38)
    # The old file is used as template for the new one,
    # so, change metadata to reflect the new assembly
    mutations.metadata['reference'] = 'GRCh38'
    
    out = open(output, 'w') if output else sys.stdout
    mapped_mutations = vcf.Writer(out, template=mutations)

    
    # --- Assembly mapping
    for record in mutations:
        chrom = record.CHROM
        pos = record.POS
        
        # Map
        record.POS = mapper.map(chrom, pos)
        
        # Write mapped data to new file
        mapped_mutations.write_record(record)
# ---


if __name__ == '__main__':
    # Command line interface
    main()