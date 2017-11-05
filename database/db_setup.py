

# < -- Import the ORM schema declaration

from schema_definition import *


# < -- Initialize the database

import os

# Initialize a database
dir = '/u/scratch/andres/data'
db_file = f'{dir}/mutations.sqlite'
db.bind(provider='sqlite', filename=db_file, create_db=True)

# Map the objects to tables
db.generate_mapping(create_tables=True)


# < -- Load mutations to the database

from mutationparser import parse_mutation, open_vcf

@db_session
def add_mutation_to_db(mutation):
    """Map the parsed mutation to a form understandable by the database"""
    
    # Map the consequences
    c = [ Consequence(**consequence) for consequence in mutation['consequences'] ]

    # Map the occurrences
    op = [ OccurrenceByProject(**occurrence) for occurrence in mutation['occurrence_by_project'] ]

    # Map the global occurrence
    og = OccurrenceGlobal(**mutation['occurrence_global'])

    # Map the mutation
    excluded = ['occurrence_global', 'occurrence_by_project', 'consequences']
    m = Mutation( **{ key : mutation[key] for key in mutation if key not in excluded },
                  occurrence_global=og
                )
    # Add the occurrences by project
    for occurrence in op:
        m.occurrences.add(occurrence)
    # Add the consequences
    for consequence in c:
        m.consequences.add(consequence)
# ---

@db_session
def load_mutations(filename, mutations_to_commit=100_000):
    # Commit once in a while
    mutations_committed = 0
    countdown_to_commit = mutations_to_commit
    # Add mutation by mutation
    for raw_mutation in open_vcf(filename):
        mutation = parse_mutation(raw_mutation)
        add_mutation_to_db(mutation)
        # Commit if neccesary
        countdown_to_commit -= 1
        if countdown_to_commit <= 0:
            countdown_to_commit = mutations_to_commit
            commit()
            # Log the commit
            mutations_committed += mutations_to_commit
            print(f'Total committed mutations: {mutations_committed}')
# ---


load_mutations('../data/ssm_all.vcf')
print('Finished')

# < -- Check the generated tables

#with db_session:
    #select( (o.affected_donors, count(o)) for o in OccurrenceGlobal ).show()
    #Mutation.select().show()
	#Consequence.select().show()
	#OccurrenceGlobal.select().show()
	#OccurrenceByProject.select().show()

# Clear the data for more tests
#db.drop_all_tables(with_all_data=True)



