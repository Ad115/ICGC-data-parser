#! /usr/bin/env python3
"""
Transform the data in the ICGC mutations VCF file from the GRCh38 to the GRch37 assembly.
"""

import click
import vcf
import sys

import ensembl


# Command line interface
@click.command()
@click.option('--input', '-i', help='VCF file to read from.')
@click.option('--output', '-o', help='VCF file to write output.')
def main(input, output):
    """Map an ICGC mutations VCF from assembly GRCh37 to GRCh38."""
    
    # --- Open the mutations file
    mutations = vcf.Reader(filename=input)

    # --- Connect to the Ensembl REST API
    #     (Web service, provides mapping between assemblies)
    c = ensembl.Client()

    # --- Open the mapped file (coordinates in GRCh38)
    # The old file is used as template for the new one,
    # so, change metadata to reflect the new assembly
    mutations.metadata['reference'] = 'GRCh38'
    
    out = open(output, 'w') if output else sys.stdout
    mapped_mutations = vcf.Writer(out, template=mutations)

    
    # --- Assembly mapping
    regions = [] # Buffers to make several queries at once
    records = []
    for record in mutations:
        chrom = record.CHROM
        pos = record.POS
        # Accumulate on buffer
        records.append(record)
        regions.append(ensembl.region_str(chrom, pos))
        
        if len(regions) >= 10: 
            mappings = c.assembly_map(region=regions,
                                  from_assembly='GRCh37',
                                  to_assembly='GRCh38')
            mappings = mappings['mappings']
            
            # Flush buffers
            print(mappings)
            # Write mapped data to new file
            record.POS = map_['mappings'][0]['mapped']['start']
            mapped_mutations.write_record(record)
# ---


if __name__ == '__main__':
    # Command line interface
    main()
