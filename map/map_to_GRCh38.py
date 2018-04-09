#! /usr/bin/env python3
import sqlite3
import sys
import click

from assemblymapper import AssemblyMapper

# Command line interface
@click.command()
@click.argument('database')
def main(database):
    """Add GRCh38 positions to the data in the database."""
    
    # --- Create the mapper object
    print('Getting mapping information from Ensembl web servers...', file=sys.stderr)
    mapper = AssemblyMapper(from_assembly='GRCh37', 
                            to_assembly='GRCh38')

    
    # --- Open the database
    print('Mapping records...', file=sys.stderr)
    connection = sqlite3.connect(database)

    
    # --- Create the new row
    editor = connection.cursor()
    editor.execute('ALTER TABLE Mutation ADD "GRCh38_pos" INTEGER')
    connection.commit()
    

    # --- Edit the database
    reader = connection.cursor()
    data = reader.execute('''SELECT mutation_id, chromosome, GRCh37_pos 
                             FROM Mutation
                          ''')
    
    for mutation_id, chrom, GRCh37_pos in data:
        GRCh38_pos = mapper.map(chrom, GRCh37_pos)
        if GRCh38_pos:
            editor.execute('''UPDATE Mutation 
                              SET GRCh38_pos=? 
                              WHERE mutation_id=?''', (GRCh38_pos, mutation_id))
            
    # --- Finalize
    editor.close()
    reader.close()
    connection.commit()
    print('Done.', file=sys.stderr)
# ---

if __name__ == '__main__':
    # Command line interface
    main()
