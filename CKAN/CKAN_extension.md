# How to develop a CKAN extension

Based on [Writing extensions tutorial — CKAN 2.9.6 documentation](https://docs.ckan.org/en/2.9/extensions/tutorial.html#creating-a-new-extension)

In this example, we build an extension with the name `ckanext-traffic_light`. The extension will add a picture of a red, yellow or green traffic light to each metadata record. The color indicates the proportion of the filled optional metadata fields for the according record. The picture is furthermore attached to each dataset in the search results.

## Setup
> I executed everything as root

Activate the Python environment where the extension should be installed. 
```sh
# default env:
. /usr/lib/ckan/default/bin/activate

# user-defined env, e.g. "ckan2.9":
. /usr/lib/ckan/ckan2.9/bin/activate
```

Install `cookiecutter`
```sh
pip install cookiecutter
```

Build foundation
```sh
# cd to ckan source dir
cd usr/lib/ckan/default/src

# use ckan helper function
ckan -c /etc/ckan/default/ckan.ini generate extension
```
After using `generate extension`, enter the information you are prompted for. This sets up the baseline structure for the extension. With `ls`, check for your extension. In this case, we find a folder called `ckanext-traffic_light`. The folder contains the basic extension structure with a plethora of folders and files. The file `./ckanext-traffic_light/setup.py` is used for installing the extension, the extension's source code goes into the folder  `./ckanext-traffic_light/ckanext/traffic_light/`.


### Plugins
A CKAN extension's functionalities are controlled by plugins. Each extension can have 1 to n plugins. Plugins are organized in classes. Cookiecutter already set up a default plugin class called `TrafficLightPlugin` that inherits from the `SingletonPlugin` class. 

>Every CKAN plugin class should inherit from `SingletonPlugin`. 

Contents of `plugin.py`:
```python
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit

class TrafficLightPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    # IConfigurer 

    def update_config(self, config_):
        toolkit.add_template_directory(config_, 'templates')
        toolkit.add_public_directory(config_, 'public')
        toolkit.add_resource('fanstatic', 'traffic_light')
```

Cookiecutter also already registered this default plugin as an entry point in `setup.py`:
```python
# ...
  entry_points='''
        [ckan.plugins]
        traffic_light=ckanext.traffic_light.plugin:TrafficLightPlugin
	'''
# ...
```

### Install and activate extension

To install the extension, `cd` into the extension's directory and run `setup.py`:
```sh
# change dir
cd /usr/lib/ckan/default/src/ckanext-traffic_light

# activate env
. /usr/lib/ckan/default/bin/activate

# install
python setup.py develop
```

Activate the extension by adding it to the CKAN config file:

```sh
nano /etc/ckan/default/ckan.ini
```

```
# ckan.ini
...
ckan.plugins = plugin_1 plugin_2 ... plugin_n traffic_light
...
```

To test if everything went fine - in our case - restart supervisor at VM. Look into the linked manual for other ways to test.

```
systemctl restart supervisor
```

If you then can load the CKAN page without errors, everything is fine. Otherwise, check error logs at `etc/ckan/default/uwsgi.ERR`.

## Add functionalities

Currently, the extension does nothing. We're now going to add content iteratively and rinse and repeat `python setup.py develop` and `systemctl restart supervisor`, to check if everything works as expected.

__CKANs Jinja Templates:__
To integrate the traffic light into the page that displays a certain metadata record, we need to adjust the content of this page. Adding content to CKAN's frontend HTML is achieved by using [Jinja templates](https://jinja.palletsprojects.com/en/3.1.x/) ([CKAN documentation](https://docs.ckan.org/en/2.9/theming/templates.html?highlight=jinja#)). In my own words: a Jinja template essentially is an HTML page that is structured into blocks. When you want to make changes to an existing Jinja template, you can load that template and apply your desired changes by directly referring to the according blocks of the template. The rest of the page is basically just copied. Furthermore, Jinja templates can execute code that is similar to the python syntax. Jinja commands are indicated by `{% <jinja_command> %}` or `{{ <jinja_command>}}`. We now take a closer look at CKAN's default template for the metadata record. The file is located at `/usr/lib/ckan/default/src/ckan/ckan/templates/package/read.html`. Note the `package` folder that contains our template; in CKAN's source code, a metadata record is referred to as a _package_.  Every file in this folder has something to do with the pages that are shown for a specific metadata record, e.g. its edit form (`../package/edit.html`). The file `../package/read.html` contains the contents of the page that is shown when you click on a certain metadata record in the catalog:

```html
{% extends "package/read_base.html" %}

{% block primary_content_inner %}
  {{ super() }}
  {% block package_description %}
    {% if pkg.private %}
      <span class="dataset-private label label-inverse pull-right">
        <i class="fa fa-lock"></i>
        {{ _('Private') }}
      </span>
    {% endif %}
    {% block package_archive_notice %}
      {% if is_activity_archive %}
        <div class="alert alert-danger">
          {% trans url=h.url_for(pkg.type ~ '.read', id=pkg.id) %}
          You're currently viewing an old version of this dataset. To see the
          current version, click <a href="{{ url }}">here</a>.
          {% endtrans %}
        </div>
      {% endif %}
    {% endblock %}
    <h1>
      {% block page_heading %}
        {{ h.dataset_display_name(pkg) }}
        {% if pkg.state.startswith('draft') %}
          [{{ _('Draft') }}]
        {% endif %}
        {% if pkg.state == 'deleted' %}
          [{{ _('Deleted') }}]
        {% endif %}
      {% endblock %}
    </h1>
    {% block package_notes %}
      {% if pkg.notes %}
        <div class="notes embedded-content">
          {{ h.render_markdown(h.get_translated(pkg, 'notes')) }}
        </div>
      {% endif %}
    {% endblock %}
    {# FIXME why is this here? seems wrong #}
    <span class="insert-comment-thread"></span>
  {% endblock %}

  {% block package_resources %}
    {% snippet "package/snippets/resources_list.html", pkg=pkg, resources=pkg.resources, is_activity_archive=is_activity_archive %}
  {% endblock %}

  {% block package_tags %}
    {% snippet "package/snippets/tags.html", tags=pkg.tags %}
  {% endblock %}

  {% block package_additional_info %}
    {% snippet "package/snippets/additional_info.html", pkg_dict=pkg %}
  {% endblock %}

{% endblock %}
```

The first line `{% extends "package/read_base.html" %}` indicates that this template is derived from another template called `read_base.html`, which is also located in the `package folder`. The file then contains multiple nested _block_ that are indicated with an opening `{% block <name_of_the_block> %}` and a closing `{% endblock %}` statement. The nesting of the blocks is defined in the upper templates from which this template is derived. The blocks themselves then contain different commands, e.g., the block `package_notes`:
```html
{% block package_notes %}
    {% if pkg.notes %}
	    <div class="notes embedded-content">
          {{ h.render_markdown(h.get_translated(pkg, 'notes')) }}
        </div>
    {% endif %}
{% endblock %}
```

Here, the template checks if the currently selected metadata record's metadata field _notes_ contains any information; and if so, the information is converted into HTML (remember, the _notes_ field in CKAN is allowed to have its content entered as Markdown) by the CKAN helper function `h.render_markdown()`. 

### Editing a templates contents

We now want our extension to add the string _TEST_ after the notes. To do this, in our extension we mirror the folder structure of CKAN (`/usr/lib/ckan/default/src/ckan/ckan/templates/package/read.html`). Currently, in our extension we already have the folder `templates` (`/usr/lib/ckan/default/src/ckanext-traffic_light/ckanext/traffic_light/templates`). In this folder we now create a new folder `package` and in this folder, the file `read.html`. To get the contents of the original `read.html` template, we simply begin the file with `{% ckan_extends %}`. The `package_notes` block is the last block of the `package_description` block. We therefore load the `package_description` block, copy its contents from the `read.html` with `{{ super() }}` and add `<p>TEST</p>` afterwards:

```
{% ckan_extends %}

{% block package_description %}
    {{ super() }}
    <p>TEST</p>
{% endblock %}
```

Now (in `/usr/lib/ckan/default/src/ckanext-traffic_light`) execute `python setup.py develop` and `systemctl restart supervisor` and review the changes in the frontend. Check the logs if you are confronted with an _internal server error_ when viewing at a certain metadata record.

---
__Adding Assets__
To show the percentage of available metadata by the means of a traffic light, we need some drawings of traffic lights. Any assets are typically put in the `../public` folder of the extension; this folder should already be created. I made some quick sketches of traffic lights at [rue-a/traffic_light_extension (github.com)](https://github.com/rue-a/traffic_light_extension/). To download the files into the public folder, execute the following commands in the terminal.

```sh
cd ckanext/traffic_light/public
git clone https://github.com/rue-a/traffic_light_extension.git

# go back to extension root
cd ..
cd ..
cd ..
```
---

We now edit our template to generate a random number that reflects the percentage of filled metadata fields, and display one of the three drawings based on the number. 

```
{% ckan_extends %}


{% block package_description %}
    {{ super() }}
    {% set percentage = range(0,100) | random %}
    {{percentage}}
    {% if percentage < 30 %}
    <img src="/traffic_light_extension/red_light.jpg" alt="red light">
    {% elif percentage < 70 %}
    <img src="/traffic_light_extension/yellow_light.jpg" alt="yellow light">
    {% else %}
    <img src="/traffic_light_extension/green_light.jpg" alt="green light">
    {% endif %}
    <br>
{% endblock %}

```

### Define Helper Functions that are Accessible from Jinja Templates

Since we want our traffic light to be meaningful, we need to change the procedure that generates the percentage value from the generation of a random number to the actual percentage of optional metadata fields that are filled. Therefore, we edit the file `plugin.py`, so that it defines a helper function that has access to the metadata scheme we're using, and that can followingly determine the percentage of optional metadata fields that are filled.

We start by defining a function that generates a random value and returns it. We then register this function as a helper and call it from our template.

```python
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
import random

# function that returns a random value 
def percentage_of_filled_fields():
    return random.randint(1,100)

class TrafficLightPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    
    # implement ITemplateHelpers
    plugins.implements(plugins.ITemplateHelpers)

    def update_config(self, config_):
        toolkit.add_template_directory(config_, 'templates')
        toolkit.add_public_directory(config_, 'public')
        toolkit.add_resource('fanstatic',
            'traffic_light')
    
    # get_helpers() is a method from ITemplateHelpers
    def get_helpers(self):
        '''register the percentage_of_filled_fields() function
        as a template helper function.'''

        # Template helper function names should begin with the name of the
        # extension they belong to, to avoid clashing with functions from
        # other extensions.
        return {'traffic_light_percentage_of_filled_fields': percentage_of_filled_fields}
```

New template:
```
{% ckan_extends %}

{% block package_description %}
    {{ super() }}
    {% set percentage = h.traffic_light_percentage_of_filled_fields() %}
    {{percentage}}    
    {% if percentage < 30 %}
    <img src="/traffic_light_extension/red_light.jpg" alt="red light">
    {% elif percentage < 80 %}
    <img src="/traffic_light_extension/yellow_light.jpg" alt="yellow light">
    {% else %}
    <img src="/traffic_light_extension/green_light.jpg" alt="green light">
    {% endif %} 
    <br>
{% endblock %}
```

### Access metadata records
In the next step, we calculate the actual percentage. In our version of CKAN, we use the _Scheming_ plugin to define three different metadata schemes; one for _datasets_, one for _processes_ and one for _workflows_. The metadata scheme of a certain record is defined in the record itself. In the template, we can change our function call to `{% set percentage = h.traffic_light_percentage_of_filled_fields(pkg) %}`, to pass the contents of the metadata record to our function. The `pkg` object is a Python dictionary that contains the internal metadata field names as keys, and the according values as values. The metadata scheme that is used can be determined by accessing the `"type"`-key of the `pkg`-dictionary.

For each type of metadata record, we define a list of keys that should be evaluated in the calculation of the percentage of filled fields. Hereby, we exclude fields that are mandatory and fields that are automatically filled by CKAN. (The "internal" representation of a certain metadata record can be accessed with the API: `https://<your-ckan-domain>/api/action/package_show?id=<metadata-record-id>`.) We furthermore define a default list of fields as fallback. We store the lists in a dictionary as the global variable `KEYS_INCLUDED` in our `plugin.py`. Subsequently, we calculate the percentage of the filled fields, depending on the metadata record type.

```python
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit

KEYS_INCLUDED = {
    "default": [
        "author", "author_email", "license_title", "notes", "url", "tags", "extras"
    ],
    "dataset": [
        "license_title", "temporal_resolution", "spatial_resolution", "was_derived_from", "theme", "tags", "is_version_of", "is_part_of", "notes", "quality_metrics", "conforms_to", "temporal_start", "temporal_end", "documentation", "url"
    ],
    "process": [ "documentation", "used", "generated", "category", "notes"
    ],
    "workflow": [
"documentation", "source_code", "rel_processes", "rel_datasets", "notes"
    ]
}

def percentage_of_filled_fields(pkg):
    # get metadata record type
    keys_included = KEYS_INCLUDED[pkg["type"]]
    if not keys_included:
        # use fallback if no matching type was found
        keys_included = KEYS_INCLUDED["default"]

    filled_fields = 0
    for key in keys_included:
        # check if key exists
        if key in pkg:
            # check if key has value (None, "", [] and {} are
            # evaluated as false in python)
            if pkg[key]:
                filled_fields = filled_fields + 1

    percentage = 0
    # this if is only for safty reasons
    if len(keys_included):
        percentage = (float(filled_fields)/float(len(keys_included)))*100

    return percentage

# ... rest of the file ...
```

Adjusted template:
```
{% ckan_extends %}

{% block package_description %}
    {{ super() }}
    {% set percentage = h.traffic_light_percentage_of_filled_fields(pkg) %}
    {{percentage}}    
    {% if percentage < 30 %}
    <img src="/traffic_light_extension/red_light.jpg" alt="red light">
    {% elif percentage < 80 %}
    <img src="/traffic_light_extension/yellow_light.jpg" alt="yellow light">
    {% else %}
    <img src="/traffic_light_extension/green_light.jpg" alt="green light">
    {% endif %} 
    <br>
{% endblock %}
```

### Loading Files
To ease the access for users of the extension, we remove the `KEYS_INCLUDED` variable from the `plugion.py` file, and rather provide it as a separate file in the JSON format.

In our extension folder (at the height of `plugin.py`), we create a file `keys_included.josn`. It has the same contents as our `KEYS_INCLUDED` variable had before, except for the default keys (they are now provided as list in `plugin.py`; `DEFAULT_KEYS =  [...]`): 

```json
{
    "dataset": [
        "license_title",
        "temporal_resolution",
        "spatial_resolution",
        "was_derived_from",
        "theme",
        "tags",
        "is_version_of",
        "is_part_of",
        "notes",
        "quality_metrics",
        "conforms_to",
        "temporal_start",
        "temporal_end",
        "documentation",
        "url"
    ],
    "process": [
        "documentation",
        "used",
        "generated",
        "category",
        "notes"
    ],
    "workflow": [
        "documentation",
        "source_code",
        "rel_processes",
        "rel_datasets",
        "notes"
    ]
}
```

To load the file, we need to provide the path. We can determine the path of our extension by using `__import__`:

```python
# gives the full description of a modules __init__.py
m = __import__('ckanext.traffic_light', fromlist=[''])
# m --> "<module 'ckanext.traffic_light' from '/usr/lib/ckan/default/src/ckanext-traffic_light/ckanext/traffic_light/__init__.py'>"
```

We include this little "trick" in a function `load_json()` (I originally found this in the scheming extension in `plugins.py` at `def _load_schema_module_path(url):`):

```python
def load_json(json_name):
    json_contents = None
    module = 'ckanext.traffic_light'
    try:
        # __import__ has an odd signature
        m = __import__(module, fromlist=[''])
    except ImportError:
        return None
    p = os.path.join(os.path.dirname(inspect.getfile(m)), json_name)
    if os.path.exists(p):
        with open(p) as file:    
            json_contents = json.load(file)
    return json_contents
```

Our final `plugin.py` for this extension now resolves to:

```python
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
import os
import inspect
import json

DEFAULT_KEYS =  ["author", "author_email", "license_title",
        "notes", "url", "tags", "extras"]

def load_json(json_name):
    json_contents = None
    module = 'ckanext.traffic_light'
    try:
        # __import__ has an odd signature
        m = __import__(module, fromlist=[''])
    except ImportError:
        return None
    p = os.path.join(os.path.dirname(inspect.getfile(m)), json_name)
    if os.path.exists(p):
        with open(p) as file:    
            json_contents = json.load(file)
    return json_contents
    

def percentage_of_filled_fields(pkg):
    keys_included = load_json('keys_included.json')

    # select subset of keys based on package type
    keys_included = keys_included[pkg['type']]

    # use fallback if no matching type was found
    if not keys_included:        
        keys_included = DEFAULT_KEYS

    filled_fields = 0
    for key in keys_included:
        # check if key exists
        if key in pkg:
            # check if key has value (None, "", [] and {} are
            # evaluated as false in python)
            if pkg[key]:
                filled_fields = filled_fields + 1

    percentage = 0
    # this if is only for safty reasons
    if len(keys_included):
        percentage = (float(filled_fields)/float(len(keys_included)))*100

    return percentage


class TrafficLightPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)

    # implement ITemplateHelpers interface 
    # (to register new helper fucntions)
    plugins.implements(plugins.ITemplateHelpers)

    # implement IDatasetForm interface 
    # (to access the dataset schemes)
    # plugins.implements(plugins.IDatasetForm)


    def update_config(self, config_):
        toolkit.add_template_directory(config_, 'templates')
        toolkit.add_public_directory(config_, 'public')
        toolkit.add_resource('fanstatic',
            'traffic_light')
    
    # get_helpers() is a method from ITemplateHelpers
    def get_helpers(self):
        '''register the percentage_of_filled_fields() function
        as a template helper function.'''

        # Template helper function names should begin with the name of the
        # extension they belong to, to avoid clashing with functions from
        # other extensions.
        return {'traffic_light_percentage_of_filled_fields': percentage_of_filled_fields}
```

### Do final cosmetics

Right now, the traffic light hangs around below the notes. We adjust the `read.html` template so that it hangs on the right side of the notes block. CKAN uses bootstrap, so we can achieve this by defining a new 'row-div' that contains two 'col-divs', where one column contains the notes and the other the traffic light. Since it looks better, we also add justification to the text of the notes block. Finally, we add a tooltip that informs about the actual percentage of filled optional metadata fields to our traffic light image.

```
{% ckan_extends %}

{% block package_description %}
    {% block package_archive_notice %}
        {{ super() }}
    {% endblock %}
    <h1>
    {% block page_heading %}
        {{ super() }}
    {% endblock %}
    </h1>
    <div class="row">
        <div class="col-sm-10" style="text-align:justify;">
            {% block package_notes %}
                {{super()}}
            {% endblock %}
        </div>
        <div class="col-sm-2">
            {% set percentage = h.traffic_light_percentage_of_filled_fields(pkg) %}
            {% set tooltip = percentage|round|int|string %}
            {% if percentage < 30 %}
                <img src="/traffic_light_extension/red_light.png" height="140" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="red light">
            {% elif percentage < 80 %}
                <img src="/traffic_light_extension/yellow_light.png" height="140" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="yellow light">
            {% else %}
                <img src="/traffic_light_extension/green_light.png" height="140" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="green light">
            {% endif %} 
        </div>
    </div>
{% endblock %}
```

We additionally want to see our traffic light right beside each dataset in the search results. By browsing through CKANs templates in `usr/lib/ckan/default/src/ckan/ckan/templates`, we find that each item in the list of search results is controlled by the snippet `usr/lib/ckan/default/src/ckan/ckan/templates/snippets/package_item.html`. Followingly, in the `templates` folder of our extension, we create a folder `snippets`, and in this folder we create the file `package_item.html` with the following contents:

```
{% ckan_extends %}

{% block content %}
  <div class="row">
    <div class="dataset-content col-sm-11">
      {% block heading %}  
        {{super()}}
      {% endblock %}
      {% block banner %}
        {{super()}}
      {% endblock %}
      {% block notes %}
        {{super()}}
      {% endblock %}
    </div>
    <div class="col-sm-1">
      {% set percentage = h.traffic_light_percentage_of_filled_fields(package) %}
      {% set tooltip = percentage|round|int|string %}
      {% if percentage < 30 %}
          <img src="/traffic_light_extension/red_light.png" height="100" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="red light">
      {% elif percentage < 80 %}
          <img src="/traffic_light_extension/yellow_light.png" height="100" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="yellow light">
      {% else %}
          <img src="/traffic_light_extension/green_light.png" height="100" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="green light">
      {% endif %} 
    </div>
  </div>
  {% block resources %}
    {{super()}}
  {% endblock %}
{% endblock %}
```


---

__Order of extensions in `ckan.ini`__
The geokurstyle extension also edits this `package_item.html` file. It does so by simply copying the content-block's content with `{{ super() }}` and adding the package's type before the contents:

```
{% ckan_extends %}
{% block content %}
{{package["type"]}}
{{super()}}
{% endblock %}
```

The `package_item.html` of our traffic light extension, on the other hand, rewrites the contents of the content-block (mainly by copying its sub-blocks though, but this is necessary to define the rows and cols correctly). If we now - in the `ckan.ini` - load the geokurstyle extension before the traffic light extension, the traffic light extension overwrites the contents (of the content-block) that were copied by the geokurstyle extension. For this reason, we must load the geokurstyle extension after the traffic light extension in the `ckan.ini`.

---


