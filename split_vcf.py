#! /usr/bin/env python3
"""
Split a VCF file into parts with the specified number of lines. Each part 
contains the same header lines as the original.
""" 

import click
import sys


def next_file(basename, header, current_file=None, files_count=None):
    ""
    if current_file:
        current_file.close()
        
    if files_count is None:
        files_count = 0
        
    new_file = open(basename + str(files_count+1) + '.vcf', 'w')
    # Write header 
    for h_line in header:
        new_file.write(h_line)
    
    return new_file, files_count+1
# ---


# Command line interface
@click.command()

@click.option('--input', '-i', 
              type=click.File('r'),
              help='VCF file to read from.')

@click.option('--outname', '-o', 
              help='VCF file to write output.')

@click.option('--lines', '-l', 
              type=int, 
              help='Lines each part will have.')

def main(input, outname, lines):
    """Split a VCF file into parts with the specified number of lines.
    
    Each part contains the same header lines as the original.
    """
    if not input:
        input = sys.stdin
    if not outname:
        outname = 'out'
    
    # Read and preserve header lines
    header = []
    line = next(input)
    while line.startswith('#'):
        header.append(line)
        line = next(input)
    
    # Take the sample
    files_count = 0
    lines_in_file = 0
    
    outfile, files_count = next_file(outname, header)
    outfile.write(line)
    lines_in_file += 1
    
    for line in input:
        outfile.write(line)
        lines_in_file += 1
        if lines_in_file >= lines:
            outfile, files_count = next_file(outname, header, outfile, files_count)
            lines_in_file = 0
# ---


if __name__ == '__main__':
    # Command line interface
    main()
