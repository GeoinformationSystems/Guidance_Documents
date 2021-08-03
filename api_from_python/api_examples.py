
# %%
# get dataset names

import requests
import json
from pprint import pprint

# GET request, no auth required
request = 'http://172.26.62.253/api/action/package_list'

response = requests.post(request)
# decode response and convert to python dictionary with json.loads
pprint(json.loads(response.content.decode()))

# %%
# create dataset


API_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2MTQxNTQxMjcsImp0aSI6IkNQM1RGdjl5WEtZanc4a1F3OTk5UTAycU42QUdiZnlJN19lQzBtNThPWkZGR2g2M2p6a2ZfWFB1aVlYYWdUSVBIYWFvSWV1X1hMNW90NVhDIn0.dMQieQcsGpP5ipgUsLnMOqOyY_pfYmLXUzsRctvMPgE'

# setup the request paramters:
request = 'http://172.26.62.253/api/action/package_create'
# Put the details of the dataset we're going to create into a dict.
dataset_dict = {
    'name': 'api_test5',
    'contact_name': 'arne',
    'theme': 'https://inspire.ec.europa.eu/theme/au',
    'spatial': '{"type":"MultiPolygon","coordinates":[[[[-20.0390625,22.05971981137765],[-20.0390625,58.14435341593962],[27.773437499999996,58.14435341593962],[27.773437499999996,22.05971981137765],[-20.0390625,22.05971981137765]]]]}',
    'owner_org': 'rue_orga'
}
headers_dict = {
    'X-CKAN-API-Key': API_TOKEN
}

# send request
response = requests.post(request,
                         data=dataset_dict,
                         headers=headers_dict
                         )
pprint(json.loads(response.content.decode()))


# %%
# update a dataset

# update a dataset


API_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2MTQxNTQxMjcsImp0aSI6IkNQM1RGdjl5WEtZanc4a1F3OTk5UTAycU42QUdiZnlJN19lQzBtNThPWkZGR2g2M2p6a2ZfWFB1aVlYYWdUSVBIYWFvSWV1X1hMNW90NVhDIn0.dMQieQcsGpP5ipgUsLnMOqOyY_pfYmLXUzsRctvMPgE'

# request the metadata of the dataset in question
request = 'http://172.26.62.253/api/action/package_show?id=api_test5'

response = requests.post(request)

# get dataset_dict form response
dataset_dict = json.loads(response.content.decode())['result']
# update the fields in question
dataset_dict['contact_name'] = 'a. r.'

# rm information about resources from dict. they can't be handled by requests.post
dataset_dict.pop('resources')

# post updated dataset

# setup the request paramters:
request = 'http://172.26.62.253/api/action/package_update'
headers_dict = {
    'X-CKAN-API-Key': API_TOKEN
}

# send request
response = requests.post(request,
                         data=dataset_dict,
                         headers=headers_dict
                         )
pprint(json.loads(response.content.decode()))


# %%
# upload a resource (with local file attached)


API_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2MTQxNTQxMjcsImp0aSI6IkNQM1RGdjl5WEtZanc4a1F3OTk5UTAycU42QUdiZnlJN19lQzBtNThPWkZGR2g2M2p6a2ZfWFB1aVlYYWdUSVBIYWFvSWV1X1hMNW90NVhDIn0.dMQieQcsGpP5ipgUsLnMOqOyY_pfYmLXUzsRctvMPgE'

# setup the request paramters:
request = 'http://172.26.62.253/api/action/resource_create'
resource_dict = {
    'package_id': 'api_test5',
    'name': 'resource name',
}
headers_dict = {
    'X-CKAN-API-Key': API_TOKEN
}
# can only contain one file
file_dict = {
    'upload': open('./api_examples.py', 'rb'),
}


response = requests.post(request,
                         data=resource_dict,
                         headers=headers_dict,
                         files=file_dict
                         )
pprint(json.loads(response.content.decode()))
