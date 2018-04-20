"""
Handle requests to the Ensembl REST API.
"""

import json
import time
import sys

from ensemblrest import EnsemblRest, EnsemblRestRateLimitError


def region_str(chrom, start, end=None, strand=+1):
    "Assemble a region string as '{chrom}:{start}..{end}:{strand}'"
    if end is None:
        end = start
        
    return '{}:{}..{}:{}'.format(chrom, start, end, strand)
# ---


class Client(EnsemblRest):
    """Handle requests to the Ensembl REST API.
    
    Optimizations are made to ensure fast handling of
    several related requests.
    
    """
    
    def make_request(self,
                     method,
                     params,
                     handle_rate_limit=True,
                     max_attempts=3):
        """Perform a given request. 
        
        If maximum request rate limit is exceded, wait to try again.
        """ 
        attempt = 0
        while attempt < max_attempts:
            attempt += 1

            try:
                # < --- Make the request
                result = method(**params)
                # exit while on success
                break

            except EnsemblRestRateLimitError:
                # Maximum requests rate exceded
                # Need to wait
                if handle_rate_limit:
                    wait_time = self.retry_after
                    sys.stderr.write('Maximum requests limit reached, waiting for' 
                                     + str(wait_time)
                                     + 'secs')
                    time.sleep(wait_time * attempt)
                else:
                    raise

            finally:
                if attempt >= max_attempts:
                    raise Exception("Max attempts exceeded (%s)" %(max_attempts))

        
        return result
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

        # Make the request
        data = self.make_request(method=self.getMapAssemblyOneToTwo,
                                 params={'asm_one':from_assembly,
                                         'asm_two':to_assembly,
                                         'species':species,
                                         'region':region})

        return data
    # ---
    
    def assembly_info(self, species='human', **kwargs):
        """List the currently available assemblies for 
        a species, along with toplevel sequences, chromosomes 
        and cytogenetic bands.
        
        Parameters:
            species: str (optional, default 'human')
                Species name/alias. Examples: 'homo_sapiens', 'human'
                
            bands: bool (optional, default False) 	
                If True, include karyotype band information. Only display 
                if band information is available.
            
            callback: str (optional) 	
                Name of the callback subroutine to be returned by the 
                requested JSONP response. Required ONLY when using JSONP 
                as the serialisation method. Please see the user guide.
                
            synonyms: bool (optional, default False)
                If set to 1, include information about known synonyms.
        """
        # Make the request
        data = self.make_request(method=self.getInfoAssembly,
                                 params={'species':species,
                                         **kwargs})

        return data
    # ---
        
# Client
