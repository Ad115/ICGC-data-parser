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

