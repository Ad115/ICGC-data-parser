#! /usr/bin/env python3.6
"""Database setup with ODO

Module used to load the mutations found in a file to a given database.

Example::

        load_mutations('ssm.vcf', 'sqlite:///ssm.sqlite::mutations')
"""


import odo
from os.path import abspath
from tempfile import NamedTemporaryFile
from ssm_datashape import all_fields
from mutationparse import mutations_to_table_from


# < --- Assemble the datashape of the data
partial_dshape = ",\n".join(key + ':' + value 
                            for key, value in all_fields) 

datashape = 'var * {\n' + partial_dshape + '\n}'
# ---
  

def load_mutations(from_file, to_db):
    """Load mutations from the given VCF file to the database.
    
    An intermediate CSV file is generated, so use carefully if needed 
    for very big files.
    """
    # 1. < --- Open the file and read the mutations
    mutations = mutations_to_table_from(from_file)
    
    # 2. < --- Create the intermediate CSV file
    
    # We create a header-less file due to the ODO library
    with NamedTemporaryFile(mode='w', suffix='.csv') as tmp:
        for i, mutation in enumerate(mutations):
            tmp.write(mutation + '\n')
                
        # 3. < --- Load the file to the database
        
        # We are still in the context of the temporary file
        
        # Pack the database as an ODO resource
        database = odo.resource(to_db,
                                dshape=datashape)
        # Use ODO to transfer data directly to the database
        odo.odo(abspath(tmp.name), to_db)
 
    # We are now out of the tmp file context, so now it has
    # been closed and deleted
    
    # Return the mutations loaded.
    return i+1
# ---  


if __name__ == '__main__':
                      
    import argparse                    
    
    # Parse the command line arguments
    parser = argparse.ArgumentParser(description='''
            From a VCF file in the format of the ICGC aggregated SSM file
            from the ICGC Data Releases, load the mutations to the specified database.
            
            The database is in the SQLAlchemy format:
            
                postgresql://username:password@54.252.14.53:10000/database::table
                mysql:///path/to/database.mysql::table
            
            Note:

                When the table name is not given, the ODO module may launch an exception like::
                
                    AssertionError: datashape must be Record type, got var * {
            '''
    )
    # Parse the mutation data file
    parser.add_argument('-i', 
                        '--input', 
                        required=True,
                        help='The input VCF file with the mutations in the ICGC Data Release format.')
    # The database arguments
    parser.add_argument('--database',
                        '--to_db',
                        required=True,
                        help='The database string in the required format.')
    # Parse...
    args = parser.parse_args()
                      
    # Load mutations to database
    n = load_mutations(from_file=args.input, 
                       to_db=args.database)
    print(f"Loaded {n} mutations to database.")
