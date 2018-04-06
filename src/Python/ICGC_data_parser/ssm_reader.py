"""
Module with functionality to read the ICGC
simple somatic mutations file.
"""

import vcf
import re
from collections import namedtuple


class BufferedReader:
    """A wrapper over a file descriptor that adds buffering functionality."""
    def __init__(self, fdesc):
        self.file = fdesc
        self.buffer = []
    # ---
    
    def __getattr__(self, attr):
        return getattr(self.file, attr)
    # ---
    
    def push(self, line):
        self.buffer.append(line)
    # ---
    
    def __iter__(self):
        return self
    
    def __next__(self):
        if self.buffer:
            return self.buffer.pop()
        return next(self.file)
    # ---
# --- BufferedReader


class SSM_Reader(vcf.Reader):
    """Reader class for the International Cancer Genome 
    Consortium aggregate file of simple somatic mutations
    from the Data Releases.
    
    Example::
        
            >>> reader = SSM_Reader(filename='data/ssm_sample.vcf')

            >>> for record in reader.parse(filters=['BRCA-EU']):
            ...    print(record.ID, record.CHROM, record.POS)
            MU66865518 1 100141201
            MU65487875 1 100160548
            MU66281118 1 100638179
            MU66254120 1 101352655
                ...
    """
    
    def __init__(self, *args, buffered=False, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Add buffering 
        self.reader = BufferedReader(self.reader)
        self.re_filters = []
    # --- 
    
    def push_line(self, line):
        self.reader.push(line)
    # ---
    
    def iter_lines(self):
        return self.reader
    # ---
    
    def next_line(self):
        return next(self.reader)
    # ---
    
    def next_array(self):
        return next(self.reader).split('\t')
    # ---
    
    def subfield_parser(self, sf_name, sep='|'):
        """Get a parser for the items of the subfield.
        
        Useful to parse the CONSEQUENCE and OCCURRENCE subfields
        of the INFO field.
        
        Example::
        
            >>> reader = SSM_Reader(filename='data/ssm_sample.vcf')
            
            >>> CONSEQUENCE = reader.subfield_parser('CONSEQUENCE')

            >>> for record in reader.parse(filters=['BRCA-EU']):
            ...    # Which genes are affected?
            ...    print(CONSEQUENCE(record)[0].gene_symbol)
            SLC27A3
            GATAD2B
            TPM3
            SHE
            ADAM15
              ...    
        """
        # Get the description of the subfield
        sf_info = self.infos[sf_name]
        
        # Get the field id
        field_id = sf_info.id

        # Get the subfields names
        subfields_str = re.findall("\(subfields: (.*?)\)", sf_info.desc)[0]
        subfields = subfields_str.split(sep)

        # Create the structure
        field_struct = namedtuple(field_id, subfields)

        # Create parser
        def parse(record):
            # Parse the field items
            return [field_struct(*item.split(sep)) 
                        for item in record.INFO[field_id]
                        if item]

        parse.field_id = sf_info.id
        parse.subfields = subfields
        return parse
    # ---
    
    def parse_lines(self, filters=None):
        """Iterate through the file, filtering out the 
        lines not matching the regular expressions given.  
        """
        if filters is None:
            filters = []
            
        # Compile filters for faster lookup
        filters = [re.compile(regex) 
                       for regex in filters 
                       if regex is not None]
        
        for line in self.reader:
            if all(filter_.search(line) for filter_ in filters):
                   # The line passes all filters
                   yield line
    # ---
                   
    def parse(self, filters=None):
        """Iterate through the records of the file, 
        filtering out the lines that do not match the 
        regular expressions given.
        
        Example::
        
            >>> reader = SSM_Reader(filename='data/ssm_sample.vcf')

            >>> for record in reader.parse(filters=['BRCA-EU']):
            ...    print(record.ID)
            MU66865518
            MU65487875
            MU66281118
            MU66254120
                ...
            
        """
        for line in self.parse_lines(filters=filters):
            # The parser reads the record from
            # self.reader, so, we must rebuffer 
            # the line to parse it.
            self.reader.push(line)
            yield next(self)
    # ---
# SSM_Reader