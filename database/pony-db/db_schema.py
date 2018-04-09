"""
Database schema definition.

This module declares the classes relevant to the database.

The classes are mapped to tables in the databases and instances of the classes
are mapped to records of the database.

"""


# < --- Import the relevant classes from the PonyORM module.
#           This module helps to map Python classes and objects to SQL tables 
#           and records.

from pony.orm import (Database, # The main db mapper object
                      Required, Optional, # The db types
                      Set, PrimaryKey)



# < --- The main database object.
#           Tables of this database are represented with classes that
#           inherit from this object's Entity attribute.
database = Database()




# < --- Definition of the database schema.
#           The classes here defined are the ones relevant to the SQL 
#           mapping of the data in the ICGC Data Releases.
class GetOrCreateMixin:
    """
    Class that implements a default get_or_create method.
    
    The method get_or_create avoids creating duplicate records.
    
    """
    
    @classmethod
    def get_or_create(cls, **params):
        'Get an instance with the given parameters or create it.'
        return cls.get(**params) or cls(**params)
# ---


class Mutation(database.Entity, GetOrCreateMixin):
    """
    The class representing a mutation.
    
    Maps to the corresponding table in the database.
    Holds main attributes such as the mutation position and definition.
    Each mutation maps to consequences and occurrences defined in other tables.
    """
    mutation_id = PrimaryKey(str)
    chromosome = Required(str)
    GRCh37_pos = Required(int)
    reference_allele = Required(str)
    mutated_allele = Required(str)
    quality = Optional(str)
    filter = Optional(str)
    occurrence_global = Required('OccurrenceGlobal')
    consequences = Set('Consequence')
    occurrences = Set('OccurrenceByProject')
# ---


class Consequence(database.Entity, GetOrCreateMixin):
    """
    A consequence of a mutation.
    
    Maps to the corresponding table in the database.
    A single consequence is defined mainly by a gene affected, a consequence
    type, and the transcripts and proteins affected, mainly.
    """
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
    mutations = Set(Mutation)


class OccurrenceByProject(database.Entity, GetOrCreateMixin):
    """
    The class representing an occurrence specific to a project.
    
    Maps to the corresponding table in the database.
    Holds affected donors and tested donors of some mutation in the project.
    """
    id = PrimaryKey(int, auto=True)
    project_code = Required(str)
    affected_donors = Required(int)
    tested_donors = Required(int)
    frequency = Required(float)
    mutations = Set(Mutation)


class OccurrenceGlobal(database.Entity, GetOrCreateMixin):
    """
    The class representing a global mutation occurrence.
    
    Maps to the corresponding table.
    Consists of the general occurrence information for some mutation, such as 
    the number of projects the mutation was found in, the number of affected 
    donors for all projects, etc.
    """
    id = PrimaryKey(int, auto=True)
    project_count = Required(int)
    mutation = Optional(str)
    affected_donors = Required(int)
    tested_donors = Required(int)
    studies = Optional(str)
    frequency = Optional(float)
    mutations = Set(Mutation)
