#! /usr/bin/env python3

import requests
import json

server = 'https://dcc.icgc.org/api/'
endpoint = 'v1/mutations'
parameters = { 'content-type': 'application/json' }

r = requests.get( server+endpoint, params=parameters)

if not r.ok:
    r.raise_for_status()
    
else:
    print( r.json().keys() )
    print( json.dumps( r.json(), indent=2 ) )
    
endpoint = 'v1/mutations/count'

parameters.update( { 
    'filters' : '{"mutation":{"affectedDonorCountTotal":{is:["1"]}}}' 
} )

r = requests.get( server+endpoint, params=parameters )

if not r.ok:
    r.raise_for_status()
    
else:
    print( r.json() )
    print( json.dumps( r.json(), indent=2 ) )
