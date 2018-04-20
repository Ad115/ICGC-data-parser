#! /usr/bin/env python3
"""
Take a sample from the input VCF file, the sample size is specified as a percentage of the total lines.

The output contains the same header lines as the original.
""" 

import click
import sys
from random import random


def validate_percentage(ctx, param, value):
    if 0 <= value <= 1:
        return value
    else:
        raise click.BadParameter('Percentage should be btw 0 and 1.')
# ---


# Command line interface
@click.command()

@click.option('--input', '-i', 
              type=click.File('r'),
              help='VCF file to read from.')

@click.option('--output', '-o', 
              type=click.File('w'),
              help='VCF file to write output.')

@click.option('--percentage', '-p', 
              type=float,
              callback=validate_percentage,
              help='Percentage of lines from input to output (a number btw 0 and 1).')

def main(input, output, percentage):
    """Take a random sample from the input VCF file, the 
    sample size is specified as a percentage of the total lines.

    The output contains the same header lines as the original.
    """
    if not input:
        input = sys.stdin
    if not output:
        output = sys.stdout
    
    # Read and preserve header lines
    line = next(input)
        
    while line.startswith('#'):
        output.write(line)
        line = next(input)
        
    # Take the sample
    if random() < percentage:
        output.write(line) # The last line read
    
    for line in input:
        if random() < percentage:
             output.write(line)   
# ---


if __name__ == '__main__':
    # Command line interface
    main()
