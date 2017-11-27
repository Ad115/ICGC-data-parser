""" Datashape of the ssm file.

In which we define the datashape of the simple somatic mutations file
from the ICGC Data Releases that we are going to parse. 

The file is structured in the following way:
  - CHROM: The chromosome the mutation is in.
  - POS: The position in the chromosome of the start of the mutation. 
         This is in the reference assembly specified in the initial comments.
  - ID: The current mutation's ICGC identifier.
  - REF: The sequence found in the reference.
  - ALT: The sequence found in the mutated sample, so that the mutation definition is REF>ALT.
  - QUAL: The quality of the read. As a general rule, a quality <10 is unreliable.
  - FILTER.
  - INFO: This field annotates predicted consequences, and seen occurrences of the current mutation. 
              The consequences are as seen by the SnpEff package.

        There may be multiple consecuences and occurrences of the same mutation, 
        and those need to be clearly specified. Thus the complex form of this field.

        In the file, the parts are separated with a semicolon (;), 
        and each part may have itself subfields, which are separated with pipes (|). 
        Alternative parts (e.g. different consequences for the mutation or occurrences in different cancer projects)
        are separated by a comma (,).

        - CONSEQUENCE: Mutation consequence predictions annotated by SnpEff. Which has itself the next subfields:
           1. gene_symbol,
           2. gene_affected,
           3. gene_strand,
           4. transcript_name,
           5. transcript_affected,
           6. protein_affected,
           7. consequence_type,
           8. cds_mutation,
           9. aa_mutation

        - OCCURRENCE: Mutation occurrence counts broken down by project. Which has itself the next subfields:
           1. project_code,
           2. affected_donors,
           3. tested_donors,
           4. frequency

        - affected_donors: Total number of donors with the current mutation.
        - mutation: Somatic mutation definition, in the form BEFORE>AFTER.
        - project_count: Number of projects with the current mutation.
        - tested_donors: Total number of donors with SSM data available.
        
"""

from collections import namedtuple, OrderedDict
# The types of the fields
# The format is that of the datashape module

# Main fields defining a mutation
main_fields = [('chromosome', 'string'),
               ('GRCh37_pos', 'int32'),
               ('mutation_id', 'string'), 
               ('reference_allele', 'string'), 
               ('mutated_allele', 'string'),
               ('quality', 'string'), 
               ('filter', 'string')]

# Fields which may have several values
tuple_fields = [('consequence','string'), 
                ('occurrence_by_project','string')]

# Fields specifying occurrence over all projects
occurrence_global_fields = [('affected_donors', 'int32'),
                            ('mutation', 'string'),
                            ('project_count','int32'), 
                            ('tested_donors', 'int32')]

# All fields that will be in the database
all_fields = main_fields + occurrence_global_fields + tuple_fields

# <-- Plain data structures
                             
# Single valued fields of a mutation
fnames = [fname for fname,ftype in main_fields + occurrence_global_fields]
MutationSimple = namedtuple('MutationSimple', fnames)
                             
# Complete data for a mutation
MutationComplete = namedtuple('MutationComplete', ['simple', 
                                                   'consequences', 
                                                   'occurrence_by_project'])