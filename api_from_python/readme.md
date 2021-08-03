# CKAN-API
official guide: https://docs.ckan.org/en/2.9/api/

## Setup

Via CKAN frontend, go to your personal page, generate an API-key, and save it at a secure location.

## Access via Python

Use Python 3 scripts to to automate tasks that require API requests.

### GET Requests

_No API key required_

This example shows all public datasets in the catalog. PPrint produces more readable output.
```python
# get dataset names

import requests
import json
from pprint import pprint


# GET request, no auth required
request = '<your-ckan-url>/api/action/package_list'

response = requests.post(request)
# decode response and convert to python dictionary with json.loads
pprint(json.loads(response.content.decode()))
```

### POST Requests

Requests that allow to update or upload datasets. Editing other things than datasets via API has to be enabled in `ckan.ini`. Adding/Editing datasets requires an API-key.

__Uploading a dataset__ Make sure a dataset with the provided name does not exists already. Also any mandatory fields need to be provided by the dataset dictionary. Additional fields from 'extras', need to be appended plainly and not in the internal structure (`contact_name` is a field from extras; internal CKAN structure of extras is `'extras': [{contact_name': 'arne'}, {...: ...}, ...] `). 
_Ownership Restrictions:_ Depending on properties in `ckan.ini`, each datasets requires an owner organization (`owner_org`); `ckan.ini` authorization options for GeoKur CKAN can be found at the bottom of this document. The name of all organizations in catalog can be acquired via API (`<ckan-url>/api/action/organization_list`).

Functional example for the GeoKur CKAN:
```python
# create dataset

import requests
import json
from pprint import pprint


API_TOKEN = '***'

# setup the request paramters:
request = '<your-ckan-url>/api/action/package_create'
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
```
__Updating a dataset__ This is essentially the same syntax as for uploading a dataset. However, it is recommended to acquire the current dataset dictionary of the dataset that should be updated via API. The following example shows how this is accomplished. Further, the field `contact_name` is updated. 

```python
# update a dataset

import requests
import json
from pprint import pprint

API_TOKEN = '***'

# request the metadata of the dataset in question
request = '<your-ckan-url>/api/action/package_show?id=api_test5'

response = requests.post(request)

# get dataset_dict form response
dataset_dict = json.loads(response.content.decode())['result']
# update the fields in question
dataset_dict['contact_name'] = 'a. r.'

# rm information about resources from dict. they can't be handled by requests.post
dataset_dict.pop('resources')

# post updated dataset

# setup the request paramters:
request = '<your-ckan-url>/api/action/package_update'
headers_dict = {
    'X-CKAN-API-Key': API_TOKEN
}

# send request
response = requests.post(request,
                         data=dataset_dict,
                         headers=headers_dict
                         )
pprint(json.loads(response.content.decode()))
```

__Uploading a resource__ Resources are uploaded the same way as datasets. If the resource file itself is uploaded along its metadata, it has to be provided in a separate dictionary.

```python
# upload a resource (with local file attached)

import requests
import json
from pprint import pprint

API_TOKEN = '***'

# setup the request paramters:
request = '<your-ckan-url>/api/action/resource_create'
resource_dict = {
    'package_id': 'api_test4',
    'name': 'test5'
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
```

## ckan.ini
```bash
## ckan.ini: Authorization Settings
ckan.auth.anon_create_dataset = false
ckan.auth.create_unowned_dataset = false
ckan.auth.create_dataset_if_not_in_organization = false
ckan.auth.user_create_groups = false
ckan.auth.user_create_organizations = false
ckan.auth.user_delete_groups = true
ckan.auth.user_delete_organizations = true
ckan.auth.create_user_via_api = false
ckan.auth.create_user_via_web = true
ckan.auth.roles_that_cascade_to_sub_groups = admin
ckan.auth.public_user_details = true
ckan.auth.public_activity_stream_detail = true
ckan.auth.allow_dataset_collaborators = false
ckan.auth.create_default_api_keys = false
```