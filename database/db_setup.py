

def open_vcf(filename):
    """A generator to handle VCF files easily"""
    # Open the VCF file
    with open(filename) as file:
        # Yield only the lines that aren't comments
        for line in file:
            if not line.startswith('#'):
                yield line
    
    
# < -- Functions to parse each mutation

def parse_mutation(raw_mutation):
    """Decompose a raw mutation line into fields, returns it as a dict"""
    # The fields the mutation is composed of
    fields = ['chromosome', 'GRCh37_pos', 
              'mutation_id', 'reference_allele', 
              'mutated_allele', 'quality', 
              'filter', 'INFO'
             ]
    # Split the mutation into fields and eliminate newline
    mutation_splitted = raw_mutation.strip().split('\t')
    # Assemble the mutation
    mutation = dict( zip(fields, mutation_splitted) )
    # Clean the fields
    mutation['GRCh37_pos'] = int(mutation['GRCh37_pos'])
    mutation.update( parse_INFO(mutation['INFO']) ) # Parse the INFO field
    del mutation['INFO']
    # Return the mutation
    return mutation
# ---


# < < -- Functions to parse the INFO field


def parse_INFO(raw_INFO):
    """Parse the raw text INFO field of a mutation into:
        - consecuences
            + gene_symbol
            + gene_affected
            + gene_strand
            + transcript_name
            + transcript_affected
            + protein_affected
            + consequence_type
            + cds_mutation
            + aa_mutation
            
        - occurrence_by_project
            + project_code
            + affected_donors
            + tested_donors
            + frequency
            
        - occurrence_global
            + affected_donors
            + tested_donors
            + mutation
            + frequency
            
    Returns the dictionary with the corresponding data
    """
    # The fields we'll split into
    fields = ['consequences', 
              'occurrence_by_project', 
              'occurrence_global'
             ]
    # Split the data into fields
    consequences, occurrence_by_project, *occurrence_global = raw_INFO.split(';')
    data = consequences, occurrence_by_project, occurrence_global
    INFO = dict( zip(fields, data) )
    # Clean the fields
    INFO['consequences'] = parse_consequences(INFO['consequences'])
    INFO['occurrence_by_project'] = parse_occurrences_by_project(
                                        INFO['occurrence_by_project']
                                    )
    INFO['occurrence_global'] = parse_occurrence_global(
                                        INFO['occurrence_global']
                                    )
    return INFO
# ---


# < < < -- Functions to parse the CONSEQUENCE subfield


def parse_consequences(raw_consequences):
    """Splits the raw comma-sepparated consequences into fields:
        + gene_symbol
        + gene_affected
        + gene_strand
        + transcript_name
        + transcript_affected
        + protein_affected
        + consequence_type
        + cds_mutation
        + aa_mutation
    * These are pipe-sepparated (|) fields
    """
    # Remove the trailing 'CONSEQUENCE=' string
    _ , trimmed_consequences = raw_consequences.split('=')
    # Separate each consequence
    consequences = trimmed_consequences.split(',')
    # Parse each consequence field
    return list( map( parse_consequence, consequences ) )
# ---


def parse_consequence(raw_consequence):
    """Splits the raw pipe-sepparated ('|') consequence into fields:
        + gene_symbol
        + gene_affected
        + gene_strand
        + transcript_name
        + transcript_affected
        + protein_affected
        + consequence_type
        + cds_mutation
        + aa_mutation
    """
    # The fields we'll split into
    fields = ['gene_symbol', 'gene_affected',
              'gene_strand', 'transcript_name', 
              'transcript_affected', 'protein_affected', 
              'consequence_type', 'cds_mutation', 
              'aa_mutation'
             ]
    # Split into fields
    consequence_splitted = raw_consequence.split('|')
    # Assemble consequence
    consequence = dict( zip(fields, consequence_splitted) )
    return consequence
# ---


# < < < -- Functions to parse the OCCURRENCE subfield (corresponding to occurrence per project)


def parse_occurrences_by_project(raw_occurrences):
    """Splits the raw comma-sepparated occurrences into fields:
        + project_code
        + affected_donors
        + tested_donors
        + frequency
    * These are pipe-sepparated (|) fields
    """
    # Remove the trailing 'OCCURRENCE=' string
    _ , trimmed_occurrences = raw_occurrences.split('=')
    # Separate each occurrence
    occurrences = trimmed_occurrences.split(',')
    # Parse each occurrence field
    return list( map( parse_occurrence_by_project, occurrences ) )
# ---


def parse_occurrence_by_project(raw_occurrence):
    """Splits the raw pipe-separated ('|') consequence into fields:
        + project_code
        + affected_donors
        + tested_donors
        + frequency
    """
    # The fields we'll split into
    fields = ['project_code', 'affected_donors',
              'tested_donors', 'frequency'
             ]
    # Split into fields
    occurrence_splitted = raw_occurrence.split('|')
    # Assemble consequence
    occurrence = dict( zip(fields, occurrence_splitted) )
    # Clean fields
    occurrence['affected_donors'] = int(occurrence['affected_donors'])
    occurrence['tested_donors'] = int(occurrence['tested_donors'])
    occurrence['frequency'] = float(occurrence['frequency'])
    return occurrence
# ---


# < < < -- Functions to parse the global occurrence

def parse_occurrence_global(raw_occurrence):
    """Splits the raw comma-separated fields of the global occurrence:
        + affected_donors
        + mutation
        + project_count
        + tested_donors
        + frequency
	+ studies
    """
    # Separate into the corresponding fields
    occurrence = dict([ keyvalue.split('=') for keyvalue in raw_occurrence ])
    # Clean the fields
    occurrence['affected_donors'] = int(occurrence['affected_donors'])
    occurrence['tested_donors'] = int(occurrence['tested_donors'])
    occurrence['project_count'] = int(occurrence['project_count'])
    occurrence['frequency'] = occurrence['affected_donors']/occurrence['tested_donors']
    return occurrence
# ---

# < -- Database schema ORM model

from pony.orm import *


db = Database()


class Mutation(db.Entity):
    id = PrimaryKey(int, auto=True)
    mutation_id = Required(str, unique=True)
    chromosome = Required(str)
    GRCh37_pos = Required(int)
    reference_allele = Required(str)
    mutated_allele = Required(str)
    quality = Optional(str)
    filter = Optional(str)
    occurrence_global = Required('OccurrenceGlobal')
    consequences = Set('Consequence')
    occurrences = Set('OccurrenceByProject')


class Consequence(db.Entity):
    id = PrimaryKey(int, auto=True)
    gene_symbol = Optional(str)
    gene_affected = Optional(str)
    gene_strand = Optional(str)
    transcript_name = Optional(str)
    transcript_affected = Optional(str)
    protein_affected = Optional(str)
    consequence_type = Optional(str)
    cds_mutation = Optional(str)
    aa_mutation = Optional(str)
    mutation = Set(Mutation)


class OccurrenceByProject(db.Entity):
    id = PrimaryKey(int, auto=True)
    project_code = Required(str)
    affected_donors = Required(int)
    tested_donors = Required(int)
    frequency = Required(float)
    mutations = Set(Mutation)


class OccurrenceGlobal(db.Entity):
    id = PrimaryKey(int, auto=True)
    project_count = Required(int)
    mutation = Optional(str)
    affected_donors = Required(int)
    tested_donors = Required(int)
    studies = Optional(str)
    frequency = Optional(float)
    mutations = Set(Mutation)


# < -- Initialize the database


import os

# Initialize a database
cwd = os.getcwd()
db_file = f'{cwd}/mutations_test.sqlite'
db.bind(provider='sqlite', filename=db_file, create_db=True)

# Map the objects to tables
db.generate_mapping(create_tables=True)


# < -- Load mutations to the database


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
def load_mutations(filename):
    for mutation_n, raw_mutation in enumerate( open_vcf(filename) ):
        mutation = parse_mutation(raw_mutation)
        add_mutation_to_db(mutation)
# ---


load_mutations('../data/ssm_mixed.vcf')

# < -- Check the generated tables

with db_session:
	Mutation.select().show()
	Consequence.select().show()
	OccurrenceGlobal.select().show()
	OccurrenceByProject.select().show()

# Clear the data for more tests
#db.drop_all_tables(with_all_data=True)



