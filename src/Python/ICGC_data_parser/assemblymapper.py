from intervaltree import IntervalTree

from . import ensembl


class AssemblyMapper:
    """Structure that optimizes the mapping between 
    diferent genome assemblies.
    
    Example::
    
        >>> mapper = AssemblyMapper(from_assembly='GRCh37'
        ...                         to_assembly='GRCh38')
        
        >>> mapper.map(chrom='1', 1000000)
        1064620
        
    """
    # No need to request several times the same info
    map_cache = dict()
    
    def __init__(self, from_assembly='GRCh37', 
                       to_assembly='GRCh38', 
                       species='human'):
        """
        Parameters
        ----------
        
        from_assembly: str, optional
                Version of the input assembly. Default 'GRCh37'.
                
        to_assembly: str, optional
                Version of the output assembly. Default 'GRCh38'.
                
        species: str, optional
                Species name/alias. Default 'human'.
        """
        # The interface to the Ensembl REST API
        self.client = ensembl.Client()
        
        # The assembly mapping is formed by mappings 
        # of genome slices. We keep at minimum the 
        # number of requests we make by fetching the 
        # whole mapping information at once and storing 
        # it in an interval tree data structure for 
        # efficient lookup.
        self.assembly_map = self._fetch_mapping(from_assembly, 
                                                to_assembly,
                                                species)
    # ---
    
    def _fetch_mapping(self, from_assembly, to_assembly, species):
        """Fetch the mapping, either make it anew or use a cached one."""
        map_key = from_assembly + to_assembly + species
        
        if map_key in self.map_cache:
            # Mapping information already fetched, return it
            return self.map_cache[map_key]
        else:
            # Need to assemble the mapping information
            mapping = self._assemble_mapping(from_assembly, 
                                             to_assembly,
                                             species)
            # Cache the assembled mapping
            self.__class__.map_cache[map_key] = mapping
            
            return mapping
    # ---
    
    def _assemble_mapping(self, from_assembly, to_assembly, species):
        """Assemble the interval tree with the information 
        for the given mapping.
        """
        client = self.client

        # Get the chromosome sizes
        genome_info = client.assembly_info(species=species)
        chromosomes = {item['name']: item['length'] 
                            for item in genome_info['top_level_region']
                            if item['coord_system'] == 'chromosome'} 

        # Initialize the mapping structure
        # (An interval tree for each chromosome)
        assembly_map = dict()

        for chrom, chrom_len in chromosomes.items():
            # Query the mapping information
            # for the entire chromosome
            region = ensembl.region_str(chrom, start=1, 
                                               end=chrom_len)
            map_ = client.assembly_map(region, from_assembly, 
                                               to_assembly)

            # Assemble into the mapping structure
            assembly_map[chrom] = self._interval_tree(map_['mappings'], 
                                                      chrom_len)

        return assembly_map
    # ---
            
    def _interval_tree(self, mappings, chrom_length):
        """Assemble an interval tree from the mapping information.
        
        An interval tree is a tree data structure that allows to 
        efficiently find all intervals that overlap with any given 
        interval or point, often used for windowing queries.
            (see https://en.wikipedia.org/wiki/Interval_tree)
        
        The mapping information is a collection where 
        each item has the shape::
            {'mapped': 
               {'assembly': 'GRCh38',
                'coord_system': 'chromosome',
                'end': 1039365,
                'seq_region_name': 'X',
                'start': 1039265,
                'strand': 1},
             'original': 
               {'assembly': 'GRCh37',
                'coord_system': 'chromosome',
                'end': 1000100,
                'seq_region_name': 'X',
                'start': 1000000,
                'strand': 1}}
        """
        interval_tree = IntervalTree()
        
        for item in mappings:
            # Assemble the interval tree.
            # Each item describes a mapping of 
            # regions btw both assemblies.
            from_ = item['original']
            to = item['mapped']

            # Need to modify to represent a half open
            # interval (as [a,b) instead of [a,b])
            from_region = from_['start'],from_['end']+1

            if to['strand'] == +1:
                to_region = to['start'],to['end']
            else:
                # Handle mappings to the reverse strand
                # (Translate them to the forward strand)
                # Visual aid to the transformation:
                #  1  2  3  4  5  6  7  8  9 10
                #  |  |  |  |  |  |  |  |  |  |
                # 10 9  8  7  6  5  4  3  2  1
                to_region = (chrom_length - to['end'] + 1, 
                             chrom_length - to['start'] + 1)
            
            interval_tree.addi(*from_region, 
                               data=to_region)
        return interval_tree
    # ---
    
    def map(self, chrom, pos):
        """Map the given position.
        
        The mapping is between the specified assemblies
        when creating the object. (default: map position 
        from assembly GRCh37 to assembly GRCh38)
        """
        # Query the interval it maps to
        interval = self.assembly_map[chrom][pos]

        if interval:
            # Calculate position from the interval
            interval = interval.pop()
            mapped_pos = interval.data[0] + (pos - interval.begin)
        else:
            # No mapping found.
            mapped_pos = None
        
        return mapped_pos
    # ---
# AssemblyMapper