"""
Handle requests to the Ensembl REST API.
"""

import json
import requests
import time


class Connection:
    """Handle requests to the Ensembl REST API."""
    
    # < --- Defaults

    grch38_server = "http://rest.ensembl.org"
    grch37_server = "http://grch37.rest.ensembl.org"

    headers = { "Content-Type" : "application/json", 
                "Accept" : "application/json"}  
    
    # Response status codes
    MAX_RATE_LIMIT = 429
    
    
    def __init__(self):
        # Initialize defaults
        self.server = self.grch38_server
        self.headers = self.headers
    # ---
    
    def region_str(self, chrom, start, end=None, strand=+1):
        "Assemble a region string as '{chrom}:{start}..{end}:{strand}'"
        if end is None:
            end = start+1
        
        return '{}:{}..{}:{}'.format(chrom, start, end, strand)
    # ---
    
    def assembly_map(self, region, from_assembly='GRCh37', 
                                   to_assembly='GRCh38', 
                                   species='human'):
        """Convert the co-ordinates of one assembly to another.
        
        Parameters
        ----------
            
            region: str
                Query region. Examples: 'X:1000000..1000100:1', 
                'X:1000000..1000100:-1', 'X:1000000..1000100'.
                
            from_assembly: str
                Version of the input assembly. Example: 'GRCh37'.
                
            to_assembly: str
                Version of the output assembly. Example: 'GRCh38'.
                
            species: str
                Species name/alias. Example: 'homo_sapiens', 'human'.
                
            
        """
        # Assemble the request data
        endpoint = (  '/map/' 
                    + species + '/'
                    + from_assembly + '/' 
                    + region + '/'
                    + to_assembly )        

        # Make the request
        r = self.make_request('GET', 
                              request=self.server+endpoint, 
                              headers=self.headers)

        # Decode the response
        data = r.json()
        return data['mappings'][0]
    # ---
        
    def make_request(self,
                     method,
                     request, 
                     headers=headers):
        """Perform a given request. 
        
        If maximum request rate limit is exceded, wait to try again.
        """
        if method == 'GET':
            method = requests.get
        elif method == 'POST':
            method = requests.post
        else:
            raise ValueError
        
        done = False
        while not done:
            # < --- Make the request
            r = method(request, headers=headers)

            # < --- Check the response
            if not r.ok:
                if r.status_code == self.MAX_RATE_LIMIT:
                    # Maximum requests rate exceded
                    # Need to wait
                    wait_time = r.headers['Retry-After']
                    time.sleep(wait)
                else:
                    r.raise_for_status()
                    
            else:
                done = True
        
        return r
    # ---