"""Database setup

Module used to load the mutations found in a file to a given SQLite database.

Example:: 
        # < -- Import the ORM schema declaration

        # Import the classes related to tables in the database
        import schema_definition as schema
        database = schema.db # Isolate database


        # < -- Open the database

        db_dir = '/u/scratch/andres/data'
        db_file = f'{db_dir}/mutations.sqlite'

        # Connect to the database
        database.bind(provider='sqlite', filename=db_file, create_db=True) 
        # Map objects to db classes
        database.generate_mapping(create_tables=True)



        load_mutations('../data/ssm_all.vcf')
        print('Finished')

        # < -- Check the generated tables

        with db_session:
            select( (o.affected_donors, count(o)) for o in OccurrenceGlobal ).show()
            Mutation.select().show()
            Consequence.select().show()
            OccurrenceGlobal.select().show()
            OccurrenceByProject.select().show()

        # Clear the data for more tests
        db.drop_all_tables(with_all_data=True)

"""

from mutationparser import read_mutations
from pony.orm import db_session
from db_schema import ( database,
                        Mutation,
                        Consequence,
                        OccurrenceByProject,
                        OccurrenceGlobal)

@db_session
def add_mutation_to_db(mutation):
    """Map the parsed mutation to a form understandable by the database and add it.
    The mutation is a dictionary with the following structure:
        - chromosome
        - GRCh37_pos 
        - mutation_id
        - reference_allele
        - mutated_allele
        - quality
        - filter
        - consecuences: List of dictionaries, each structured in the next way:
            + gene_symbol
            + gene_affected
            + gene_strand
            + transcript_name
            + transcript_affected
            + protein_affected
            + consequence_type
            + cds_mutation
            + aa_mutation

        - occurrence_by_project: List of dictionaries, each structured in the next way:
            + project_code
            + affected_donors
            + tested_donors
            + frequency

        - occurrence_global: Dictionary with the following keys:
            + affected_donors
            + tested_donors
            + mutation
            + frequency
    """
    
    # Map the consequences
    c = [ Consequence.get_or_create(**consequence) for consequence in mutation['consequences'] ]

    # Map the occurrences
    op = [ OccurrenceByProject.get_or_create(**occurrence) for occurrence in mutation['occurrence_by_project'] ]

    # Map the global occurrence
    og = OccurrenceGlobal.get_or_create(**mutation['occurrence_global'])

    # Map the mutation
    excluded = ['occurrence_global', 'occurrence_by_project', 'consequences']
    m = Mutation( **{ key : mutation[key] for key in mutation if key not in excluded },
                  occurrence_global=og, occurrences=op, consequences=c
                )
# ---

@db_session
def load_mutations(mutations, mutations_to_commit=100_000):
    """
    From the iterable 'mutations', fetch the mutations and add them to 
    the database in use.
    """
    # Check how many mutations are already in the database
    mutations_before = Mutation.select().count()
    print(f'Mutations already in the database: {mutations_before}')
    
    # Commit once in a while
    mutations_committed = 0
    countdown_to_commit = mutations_to_commit
    # Add mutation by mutation after the last one added
    for n, mutation in enumerate(mutations):
        if n+1 > mutations_before:
            add_mutation_to_db(mutation)
            
            # Commit if neccesary
            countdown_to_commit -= 1
            if countdown_to_commit <= 0:
                countdown_to_commit = mutations_to_commit
                commit()
                
                # Log the commit
                mutations_committed += mutations_to_commit
                print(f'Total committed mutations: {mutations_committed}, Total in database: {mutations_before + mutations_committed}')
    print(f'Total mutations added to database: {mutations_before + mutations_committed}')
# ---
