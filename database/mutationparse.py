"""
Mutation parse.

Module with functions destined to parse mutations in
format of the ICGC Data Release's SSM aggregated file.

Example::

       mutations_to_table_from('ssm.vcf', 
                               out_separator='\t',
                               out_header=True)

"""

from ssm_datashape import (MutationSimple, 
                           MutationComplete, 
                           all_fields)

# < --- Output as table

def mutations_to_table(mutations, separator=',', header=True):
    """Return a table representation of the mutations file.
    
    Creates a generator that dispatches line by line.
    """
    # Header (schema) line
    if header:
        yield separator.join([fname for fname,ftype in all_fields])

    # From the complete data, assemble the database items
    for mutation in mutations:
        # Begin assembling the output
        mutation_prefix = separator.join(mutation.simple)
        # Each line must have only one of the items of
        # the multiple values in the occurrence_by_project
        # and consequence part of the data.
        for occurrence in mutation.occurrence_by_project:
            for consequence in mutation.consequences:
                # Mutation line
                yield separator.join([mutation_prefix, 
                                      consequence,
                                      occurrence])
# ---

def mutations_to_table_from(filename, separator=',', header=True):
    """Yield, one by one, the mutations in a table formatted string.
    
    The separator and header arguments refer to the output format, 
    the input format is in the VCF standard.
    
    """
    return mutations_to_table(clean_mutations(filename),
                              separator=separator,
                              header=header)
# ---

# < --- VCF file parsing

def clean_mutations(filename):
    """
    Helper function that returns a generator of the mutations parsed from the file.
    
    The format is suitable for creating a first file for database setup.
    """
    for raw_mutation in open_vcf(filename):
        # Yield the parsed mutation
        yield clean_mutation(raw_mutation)
# ---

def open_vcf(filename):
    """A generator to handle VCF files easily.
    
    Open the file with the given filename and yield every line that doesn't
    start with '#' (such as comment and header lines)
    """
    # Open the VCF file
    with open(filename) as file:
        # Yield only the lines that aren't comments
        for line in file:
            if not line.startswith('#'):
                yield line
# ---

# < --- Mutation parsing

# < -- Parse the raw mutation 

def clean_mutation(raw_mutation):
    'Decompose a raw mutation line into fields, returns it as a dict'
    # Split the mutation into fields and eliminate newline
    *main_fields, rawINFO = raw_mutation.strip().split('\t')
    # Parse the INFO
    (consequences, 
     occurrence_by_project, 
     occurrence_global) = clean_INFO(rawINFO)
    # Assemble the mutation
    mutation = MutationSimple(*main_fields, 
                              *occurrence_global)
    # Return the mutation
    return MutationComplete(mutation, consequences, occurrence_by_project)
# ---

def clean_INFO(rawINFO):
    """Parse the raw text INFO field of a mutation into:
        - consecuences
        - occurrence_by_project
        - occurrence_global
    """
    # Split the data into fields
    (consequences, 
     occurrence_by_project, 
     *occurrence_global) = rawINFO.split(';')
    # Clean the fields
    consequences = clean_tuple_field(consequences)
    occurrence_by_project = clean_tuple_field(occurrence_by_project)
    occurrence_global = clean_occurrence_global(occurrence_global)
    
    return consequences, occurrence_by_project, occurrence_global
# ---

def clean_tuple_field(raw_field):
    """Cleanup of a field that may have a variable number of values.
    
    A tuple field is of the form 'FIELD_NAME=value1,value2,...'
    
    Returns (value1, value2, ...)
    """
    # Remove the trailing 'FIELD_NAME=' string
    _ , trimmed_field = raw_field.split('=')
    # Separate each key, value pair
    values = trimmed_field.split(',')
    
    return values
# ---

def clean_occurrence_global(raw_occurrence):
    """Split the raw comma-separated fields of the global occurrence.
        
    Accepts a collection of elements of the form 'KEY=value'.
    Returns a colection with the values 'value'
    """
    # Separate into the corresponding fields
    occurrence = dict( keyvalue.split('=') for keyvalue in raw_occurrence )
    # Handle the case of the files before data release 25
    if 'studies' not in occurrence:
        occurrence['studies'] = 'None'
    return [value for key,value in occurrence.items()]
# ---
