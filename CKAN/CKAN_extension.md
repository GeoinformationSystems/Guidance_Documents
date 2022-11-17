# How to develop a CKAN extension

In this example, we build an extension with the name `ckanext-traffic_light`. The extension will add a picture of a red, yellow or green traffic light to each metadata record. The color indicates the proportion of the filled optional metadata fields for the according record. The picture is furthermore attached to each dataset in the search results.

Official CKAN extending guide: [Writing extensions tutorial — CKAN 2.9.6 documentation](https://docs.ckan.org/en/2.9/extensions/tutorial.html#creating-a-new-extension)
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

Cookiecutter also registered this default plugin as an entry point in `setup.py` already: 
```python
# ...
  entry_points='''
        [ckan.plugins]
        traffic_light=ckanext.traffic_light.plugin:TrafficLightPlugin
	'''
# ...
```

### Install and Activate Extension

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

To test if everything went fine, restart your server. Check error logs at `etc/ckan/default/uwsgi.ERR`, if you cannot load your CKAN webpage without errors.

## Add functionalities

Currently, the extension does nothing. We're now going to add content iteratively and rinse and repeat `python setup.py develop` and "restart server" (on my VM this is `systemctl restart supervisor`), to check if everything works as expected.

__CKANs Jinja Templates:__
To integrate a traffic light into the page that displays a certain metadata record, we need to adjust the content of this page. Adding content to CKAN's frontend HTML is achieved by using [Jinja templates](https://jinja.palletsprojects.com/en/3.1.x/) ([CKAN documentation](https://docs.ckan.org/en/2.9/theming/templates.html?highlight=jinja#)). In my own words: a Jinja template essentially is an HTML page that is structured into blocks. When you want to make changes to an existing Jinja template, you can load that template and apply your desired changes by only referring to the according blocks of the template. The rest of the page is basically just copied. Furthermore, Jinja templates can execute code that is similar to the python syntax. Jinja commands are indicated by `{% <jinja_command> %}` or `{{ <jinja_command>}}`. We now take a closer look at CKAN's default template for the metadata record. The file is located at `/usr/lib/ckan/default/src/ckan/ckan/templates/package/read.html`. Note the `package` folder that contains our template; in CKAN's source code, a metadata record is referred to as a _package_.  Every file in this folder has something to do with the pages that are shown for a specific metadata record, e.g. its edit form (`../package/edit.html`). The file `../package/read.html` contains the contents of the page that is shown when you click on a certain metadata record in the catalog:

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

### Edit a template's contents

We now want our extension to add the string _TEST_ after the notes. To do this, in our extension we mirror the folder structure of CKAN (`/usr/lib/ckan/default/src/ckan/ckan/templates/package/read.html`). Currently, in our extension we already have the folder `templates` (`/usr/lib/ckan/default/src/ckanext-traffic_light/ckanext/traffic_light/templates`). In this folder we now create a new folder `package` and in this folder, the file `read.html`. To get the contents of the original `read.html` template, we simply begin the file with `{% ckan_extends %}`. The `package_notes` block is the last block of the `package_description` block. We therefore load the `package_description` block, copy its contents from the `read.html` with `{{ super() }}` and add `<p>TEST</p>` afterwards:

```
{% ckan_extends %}

{% block package_description %}
    {{ super() }}
    <p>TEST</p>
{% endblock %}
```

Now (in `/usr/lib/ckan/default/src/ckanext-traffic_light`) execute `python setup.py develop` and `systemctl restart supervisor` and review the changes in the frontend. Check the logs if you are confronted with an _internal server error_ when viewing at a certain metadata record.


### Add Static Files
To show the percentage of available metadata by the means of a traffic light, we need some drawings of traffic lights. Any static files (images, PDFs, ...) are typically put in the `../public` folder of the extension; this folder is already created. The files we use for the traffic light are available at the finished extension's page on [GitHub](https://github.com/rue-a/ckanext-traffic_light/blob/master/ckanext/traffic_light/public/).  Any file in the public folder can be accessed from the HTML templates by `"/<filename>"`, e.g., `<img src="/yellow_light.jpg"`. Additionally, all files in the public folder are accessible from the frontend by `<your-ckan-domain>/<filename>`, e.g., `<your-ckan-domain>/yellow_light.png`.

We now edit our template to generate a random number that reflects the percentage of filled metadata fields, and display one of the three drawings based on the number. 

```
{% ckan_extends %}


{% block package_description %}
    {{ super() }}
    {% set percentage = range(0,100) | random %}
    {{percentage}}
    {% if percentage < 30 %}
    <img src="/red_light.jpg" alt="red light">
    {% elif percentage < 70 %}
    <img src="/yellow_light.jpg" alt="yellow light">
    {% else %}
    <img src="/green_light.jpg" alt="green light">
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
def evaluate_fields():
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
        '''register the evaluate_fields() function
        as a template helper function.'''

        # Template helper function names should begin with the name of the
        # extension they belong to, to avoid clashing with functions from
        # other extensions.
        return {'traffic_light_evaluate_fields': evaluate_fields}
```

New template:
```
{% ckan_extends %}

{% block package_description %}
    {{ super() }}
    {% set percentage = h.traffic_light_evaluate_fields() %}
    {{percentage}}    
    {% if percentage < 30 %}
    <img src="/red_light.jpg" alt="red light">
    {% elif percentage < 80 %}
    <img src="/yellow_light.jpg" alt="yellow light">
    {% else %}
    <img src="/green_light.jpg" alt="green light">
    {% endif %} 
    <br>
{% endblock %}
```

### Access metadata records
In the next step, we calculate the actual percentage. In our version of CKAN, we use the _Scheming_ plugin to define three different metadata schemes; one for _datasets_, one for _processes_ and one for _workflows_. The metadata scheme of a certain record is defined in the record itself. In the template, we can change our function call to `{% set percentage = h.traffic_light_evaluate_fields(pkg) %}`, to pass the contents of the metadata record to our function. The `pkg` object is a Python dictionary that contains the internal metadata field names as keys, and the according values as values. The metadata scheme that is used can be determined by accessing the `"type"`-key of the `pkg`-dictionary.

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

def evaluate_fields(pkg):
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
    {% set percentage = h.traffic_light_evaluate_fields(pkg) %}
    {{percentage}}    
    {% if percentage < 30 %}
    <img src="/red_light.jpg" alt="red light">
    {% elif percentage < 80 %}
    <img src="/yellow_light.jpg" alt="yellow light">
    {% else %}
    <img src="/green_light.jpg" alt="green light">
    {% endif %} 
    <br>
{% endblock %}
```

### Load Files
To ease the access for users of the extension, we remove the `KEYS_INCLUDED` variable from the `plugion.py` file, and rather provide it as a separate file in the JSON format.

In our extension folder (at the height of `plugin.py`), we create a file `fields.json`. It has the same contents as our `KEYS_INCLUDED` variable had before, except for the default keys (they are now provided as list in `plugin.py`; `DEFAULT_KEYS =  [...]`): 

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
    

def evaluate_fields(pkg):
    keys_included = load_json('fields.json')

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
        '''register the evaluate_fields() function
        as a template helper function.'''

        # Template helper function names should begin with the name of the
        # extension they belong to, to avoid clashing with functions from
        # other extensions.
        return {'traffic_light_evaluate_fields': evaluate_fields}
```



### Styling, Bootstrap

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
            {% set percentage = h.traffic_light_evaluate_fields(pkg) %}
            {% set tooltip = percentage|round|int|string %}
            {% if percentage < 30 %}
                <img src="/red_light.png" height="140" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="red light">
            {% elif percentage < 80 %}
                <img src="/yellow_light.png" height="140" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="yellow light">
            {% else %}
                <img src="/green_light.png" height="140" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="green light">
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
      {% set percentage = h.traffic_light_evaluate_fields(package) %}
      {% set tooltip = percentage|round|int|string %}
      {% if percentage < 30 %}
          <img src="/red_light.png" height="100" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="red light">
      {% elif percentage < 80 %}
          <img src="/yellow_light.png" height="100" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="yellow light">
      {% else %}
          <img src="/green_light.png" height="100" title="{{tooltip}}% of optional meta-&#10data fields are filled." alt="green light">
      {% endif %} 
    </div>
  </div>
  {% block resources %}
    {{super()}}
  {% endblock %}
{% endblock %}
```


### Order of extensions

The order in which extensions are loaded is defined in `ckan.ini`. Another extension (here geokurstyle) also edits this `package_item.html` file. It does so by simply copying the content-block's content with `{{ super() }}` and adding the package's type before the contents:

```
{% ckan_extends %}
{% block content %}
{{package["type"]}}
{{super()}}
{% endblock %}
```

The `package_item.html` of our traffic light extension, on the other hand, rewrites the contents of the content-block (mainly by copying its sub-blocks though, but this is necessary to define the rows and cols correctly). If we now - in the `ckan.ini` - load the geokurstyle extension before the traffic light extension, the traffic light extension overwrites the contents (of the content-block) that were copied by the geokurstyle extension. For this reason, we must load the geokurstyle extension after the traffic light extension in the `ckan.ini`.

### Reading `ckan.ini` properties

We now want to give the user the ability to assign weights to the metadata fields that are defined in `fields.json`. We therefore change the schema of `fields.json`. Since the tooltip "xx percent of optional metadata fields are filled", doesn't make sense for weighted fields, we want to remove the tooltip, if the weighting-option is used. We want to control the behavior with a configuration variable in `ckan.ini`:
```
...
ckan.plugins = ... traffic_light

# ckanext.traffic_light: Define whether weights are used or not (default is false)
ckan.traffic_light = ckanext.traffic_light.weights = true
...
```

To achieve this, we need to define and register a new function in `plugin.py` that reads and evaluates our new configuration variable.

Excerpts from `plugin.py`
```python
...

def apply_weights():
    # toolkit.config.get(...) reads value of "ckanext.traffic_light.weights" 
    # from ckan.ini and sets value to false if no variable is provided.

    # toolkit.asbool(...) evaluates a string as bool.

    # with try ... except ValueError we catch typos from ckan.ini, e.g.,
    # "ckanext.traffic_light = fasle" and set the variable to False in case.

    try:
        return toolkit.asbool(toolkit.config.get('ckanext.traffic_light.weights', 'false'))
    except ValueError:
        return False

...

class TrafficLightPlugin(plugins.SingletonPlugin):
    ...
    # get_helpers() is a method from ITemplateHelpers
    def get_helpers(self):
        '''register the evaluate_fields() function
        as a template helper function.'''

        # Template helper function names should begin with the name of the
        # extension they belong to, to avoid clashing with functions from
        # other extensions.
        return {
            'traffic_light_evaluate_fields': evaluate_fields,
            'traffic_light_apply_weights': apply_weights
        }
```

We then in both `package_item.html` and `read.html` check the value of the configuration variable and remove (set to an empty string) the title accordingly, e.g. in `read.html`:

```

...
{% set evaluation = h.traffic_light_evaluate_fields(package) %}        
{% set tooltip = evaluation|round|int|string + "% of optional meta-\ndata fields are filled."%}
{% if h.traffic_light_apply_weights()%}
    {% set tooltip = "" %}
{% endif %}
{% if evaluation < 30 %}
    <img src="/red_light.png" height="140" title="{{tooltip}}" alt="red light">
{% elif evaluation < 80 %}
    <img src="/yellow_light.png" height="140" title="{{tooltip}}" alt="yellow light">
{% else %}
    <img src="/green_light.png" height="140" title="{{tooltip}}" alt="green light">
{% endif %}
...
```

We finally need to adapt the schema of `fields.json` and change the evaluation logic in `evaluate_fields()`. Since the new schema is somewhat more complex, we create a new file (`fields_weighted`), which is only used if `weights = true`. This way, we can keep the simple configuration for users if no weightings are required. 

`fields_weighted.json`
```
{
    "dataset": [
        {
            "field_name": "license_title",
            "weight": 1
        },
        {
            "field_name": "temporal_resolution",
            "weight": 1
        },
        {
            "field_name": "spatial_resolution",
            "weight": 1
        },
        {
            "field_name": "was_derived_from",
            "weight": 1
        },
        {
            "field_name": "theme",
            "weight": 1
        },
        {
            "field_name": "tags",
            "weight": 1
        },
        {
            "field_name": "is_version_of",
            "weight": 1
        },
        {
            "field_name": "is_part_of",
            "weight": 1
        },
        {
            "field_name": "notes",
            "weight": 1
        },
        {
            "field_name": "quality_metrics",
            "weight": 1
        },
        {
            "field_name": "conforms_to",
            "weight": 1
        },
        {
            "field_name": "temporal_start",
            "weight": 1
        },
        {
            "field_name": "temporal_end",
            "weight": 1
        },
        {
            "field_name": "documentation",
            "weight": 1
        },
        {
            "field_name": "url",
            "weight": 1
        }
    ],
    "process": [
        {
            "field_name": "documentation",
            "weight": 1
        },
        {
            "field_name": "used",
            "weight": 1
        },
        {
            "field_name": "generated",
            "weight": 1
        },
        {
            "field_name": "category",
            "weight": 1
        },
        {
            "field_name": "notes",
            "weight": 1
        }
    ],
    "workflow": [
        {
            "field_name": "documentation",
            "weight": 1
        },
        {
            "field_name": "source_code",
            "weight": 1
        },
        {
            "field_name": "rel_processes",
            "weight": 1
        },
        {
            "field_name": "rel_datasets",
            "weight": 1
        },
        {
            "field_name": "notes",
            "weight": 1
        }
    ]
}
```

`evaluate_fields()`
```python
def evaluate_fields(pkg):
    schema = None
    weights = apply_weights()
    if weights:
        schema = load_json('fields_weighted.json')
    else:
        schema = load_json('fields.json')

    # select subset of keys based on package type
    try: 
        fields = schema[pkg['type']]
    # use fallback if no matching type was found
    except KeyError :
        fields = DEFAULT_KEYS
        weights = False

    if weights:
        max_value = 0
        filled_value = 0
        for field in fields:
            max_value = max_value + field["weight"]
            if field["field_name"] in pkg:
                if pkg[field["field_name"]]:
                    filled_value = filled_value + field["weight"] 
        return float(filled_value)/float(max_value)
    else:
        filled_fields = 0
        for key in fields:
            # check if key exists
            if key in pkg:
                # check if key has value (None, "", [] and {} are
                # evaluated as false in python)
                if pkg[key]:
                    filled_fields = filled_fields + 1
        percentage = 0
        # this if is only for safty reasons
        if len(fields):
            percentage = (float(filled_fields)/float(len(fields)))
        return percentage
```

Since percentage stopped making sense for applied weightings, we always return a value between 0 and 1 and multiply with 100 only for the tooltip in the HTMLs(example for `read.html` below). Finally, we define two more configuration variables and the according functions to let the users control limits for the traffic light (`ckanext.traffic_light.yellow_limit`, `ckanext.traffic_light.green_limit`).

`plugin.py`
```python
...
def get_yellow_limit():
    try:
        return float(toolkit.config.get('ckanext.traffic_light.yellow_limit', '0.3'))
    except ValueError:
        return 0.3

def get_green_limit():
    try:
        return float(toolkit.config.get('ckanext.traffic_light.green_limit', '0.8'))
    except ValueError:
        return 0.8
...
class TrafficLightPlugin(plugins.SingletonPlugin):
    ...
    def get_helpers(self):
        ...
        return {
            ...
            'traffic_light_get_yellow_limit': get_yellow_limit,
            'traffic_light_get_green_limit': get_green_limit
        }
```

`read.html`
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
            {% set evaluation = h.traffic_light_evaluate_fields(package) %}        
            {% set tooltip = (evaluation*100)|round|int|string + "% of optional meta-\ndata fields are filled."%}
            {% if h.traffic_light_apply_weights()%}
              {% set tooltip = "The weighted evaluation of metadata\nprovision yielded " + (evaluation*100)|round|int|string + " of 100 points." %}
            {% endif %}            
            {% if evaluation < h.traffic_light_get_yellow_limit() %}
                <img src="/red_light.png" height="140" title="{{tooltip}}" alt="red light">
            {% elif evaluation < h.traffic_light_get_green_limit() %}
                <img src="/yellow_light.png" height="140" title="{{tooltip}}" alt="yellow light">
            {% else %}
                <img src="/green_light.png" height="140" title="{{tooltip}}" alt="green light">
            {% endif %}
        </div>
    </div>
{% endblock %}
```


### Create a Subpage

We now want to create a page where frontend users can review which fields and which weightings are used in the evaluation of the metadata provision and which limits are defined for the traffic light to switch color. 

Initially, in the `templates` folder, we create the folder `ckanext`, and in this folder we create `traffic_light`. We then create the file `templates/ckanext/traffic_light/reference_page.html` with the following contents:

```
{% extends "page.html" %}

{% block primary %}
<h1>Traffic Light Extension Reference Page</h1>
{% endblock %}

{% block secondary %}
{% endblock %}
```

To make this page appear at `<your-ckan-domain>/traffic-light-reference`, we need to do two things. First, we need to define a "Controller" class with a method that renders our page; and second, we need to link this method to `<your-ckan-domain>/traffic-light-reference`.

The first is achieved in a new file `controller.py` that is created at the extension's top-level (at the level of `plugin.py`):

`controller.py`
```python
from ckan.lib.base import BaseController, render

class TrafficLightController(BaseController):
    def render_reference_page(self):
        return render('ckanext/traffic_light/reference_page.html')
```

The second is achieved by adding the `IRoutes` plugin to our `TrafficLightPlugin`, and adding the new route (`<your-ckan-domain>/traffic-light-reference`) to the routes-map by using the `after_map()` method. In this function, we call the method `map.connect()`, which takes four arguments. The first argument is somewhat opaque to me, it seems that you can type anything in here (I guess it's the name of the new route and has to be unique among all extensions). The second argument is the sub path where the page should be rendered. The third defines which controller holds the rendering method. And the fourth defines which rendering method of the controller should be called.

`plugin.py`
```python
...
class TrafficLightPlugin(plugins.SingletonPlugin):
    ...
    plugins.implements(plugins.IRoutes, inherit=True)
        
        def after_map(self, map):
            map.connect(
                'traffic-light-reference',
                '/traffic-light-reference',
                controller = 'ckanext.traffic_light.controller:TrafficLightController',
                action = 'render_reference_page'
            )
            return map
    ...
...
```

With the rendering and routing of the page set up, we can now fill our `reference_page.html` with content:

```
{% extends "page.html" %}

{% block breadcrumb_content %}
  <li class="active">{{ _('Traffic Light Extionsion Reference') }}</li> 
{% endblock %}

{% block primary %}
<div class = "row">
    <h1>Traffic Light Extension Reference Page</h1>
</div>

<div class = "row">
    This page gives an overview over the configuration of the traffic light extension.
    The extension shows a traffic light with either a green, yellow or red light, based
    on the evaluation of provision of metadata for each metadata record. Extension users 
    can can configure which fields - depending on metadata record type - are evaluated; 
    if weights for these fields should be included in the evaluation; and at which limits 
    the traffic light switches color.
</div>
<div class = "row">
    <h3>Weights enabled:</h3>
    <div class="col-sm-1"></div>
    <div class="col-sm-11" style="font-size: larger;"><em>{{ h.traffic_light_apply_weights() }}</em></div>
</div>

<div class="row">
    <h3>Traffic Light Color Value Ranges</h3>
    <p>The evaluation of the metadata provision always yields a value between 0 and 1. Depending 
        on this value the traffic light either shows a green, yellow or red light. If no weights 
        are applied, this value resolves to the percentage of filled metadata fields that are 
        inculded in the calculation. 
    </p>
    <div class="col-sm-1"></div>
    <div class="col-sm-11" style="font-size: larger;">
        Green Light: <em>{{h.traffic_light_get_green_limit()}} &#8804; value &#8804; 1</em><br>
        Yellow Light: <em>{{h.traffic_light_get_yellow_limit()}} &#8804; value < {{h.traffic_light_get_green_limit()}}</em><br>
        Red Light: <em>0 &#8804; value < {{h.traffic_light_get_yellow_limit()}}</em>
    </div>
</div>
<div class="row">
    <h3>Evaluated Metadata Fields</h3>
    <p>Users of the extension can - for each metadata record type in the catalog - specify which metadata
        fields (and possibly with which weight) are evalauted with this extension, e.g., all optional 
        metadata fields.
    </p>
    <div class="col-sm-1"></div>
    <div class="col-sm-6">
        {% set record_types = h.traffic_light_get_metadata_record_types()%}
        <hr>
        {% for record_type in record_types %}
            <em style="font-size: larger;">{{record_type}}</em>
            <br>
            <br>
            <table class="table table-striped table-bordered table-condensed">
                <tr>
                    <th>Field Name</th>
                    <th>Weight</th>
                </tr>
            {% for field in h.traffic_light_get_evaluated_metadata_record_fields(record_type) %}
                <tr>
                    <td>{{field}}</td>
                    <td>
                        {% if h.traffic_light_apply_weights() %}
                        {{h.traffic_light_get_weight(record_type, field)}}
                        {% else %}
                        -
                        {% endif %}
                    </td>
                </tr>
            {% endfor %}
            </table>
            <hr>
        {% endfor %}
    </div>
</div>


{% endblock %}

{% block secondary %}
{% endblock %}
```

There is nothing really new here. The only thing is that we defined the three new helper functions `h.traffic_light_get_metadata_record_types()`, `h.traffic_light_get_evaluated_metadata_record_fields(...)` and `h.traffic_light_get_weight(...)`.

`plugin.py` (omitted the registration part in `get_helpers()`)
```python
...
def get_metadata_record_types():
    schema = None
    weights = apply_weights()
    if weights:
        schema = load_json('fields_weighted.json')
    else:
        schema = load_json('fields.json')
    if schema.keys():
        return schema.keys()
    else:
        # if schema is empty  return CKANs default
        # metadata record type name.
        return ['dataset']

def get_evaluated_metadata_record_fields(record_type):
    schema = None
    weights = apply_weights()
    if weights:
        schema = load_json('fields_weighted.json')
    else:
        schema = load_json('fields.json')
    if schema[record_type]:
        if weights:
            field_names = [k['field_name'] for k in schema[record_type]]
            return field_names
        else: 
            return schema[record_type]
    else:
        return DEFAULT_FIELD_NAMES

def get_weight(record_type, field_name):
    schema = load_json('fields_weighted.json')
    if schema:
        for item in schema[record_type]:
            if item['field_name'] == field_name:
                return item['weight']
    return None
...
```

With the reference page set up, we finally enclose our traffic lights with an `<a>`-tag, so that users are redirected to the reference page, when clicking on them, e.g.,: `<a href="/traffic-light-reference" target="_blank"><img src="/red_light.png" height="140" title="{{tooltip}}" alt="red light"></a>`. 

### Interfacing other extensions

The problem with this version of our reference page is that it displays the internal keys of our metadata fields instead of the labels that are displayed when reviewing a certain metadata record. Most CKANs don't use the default metadata schema, but rather define specific schemas, depending on the use case. These specific schemas are usually defined by using the CKAN extension [scheming](https://github.com/ckan/ckanext-scheming).  We now want to import the schema definitions from scheming and find the labels of our internal keys. In `plugin.py`, we therefore import a helper function from the scheming plugin. To prevent our extension from breaking, if the scheming extension is not installed, we put the import in a `try: ... except: ...` clause and assume that the extension is not installed if the import fails:

```python
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
import os
import inspect
import json 

scheming = True
try:
    from ckanext.scheming.helpers import scheming_get_dataset_schema as get_scheming_schema
except:
    scheming = False
...
```

The scheming helper method `scheming_get_dataset_schema(...)` requires one argument: the metadata record type (or package type). With the scheming extension, you can define multiple types of metadata records, with each of them having its own schema. With the helper method, you get the metadata schema of the metadata record type you gave as argument. The required fields of the general scheming schema are displayed below.

General structure and required fields of the scheming schema that is used to define the schema of a certain metadata record type:
```
{
	...,
	"about": <schema_description/label for frontend>
	...
	"dataset_fields": [
		...,
		"field_name": "<internal_field_name>"
		"label": "<label_for_frontend>",
		...
	]
}
```

With this knowledge, we add two more helper methods to our `plugin.py`:

```python
def get_record_type_label(record_type):
    if scheming:
        scheming_schema = get_scheming_schema(record_type)
        return scheming_schema['about']
    else:
        return None

def get_field_label(record_type, field_name):
    if scheming:
        scheming_schema = get_scheming_schema(record_type)
        for field in scheming_schema['dataset_fields']:
            if field['field_name'] == field_name:
                return field['label']
    else:
        return None
```

If the helper method from the scheming extension could be loaded, we return the according labels, otherwise we return `None`. We finally integrate these methods in our `reference_page.html` (at the bottom, where we create the table):

```
...
{% set record_types = h.traffic_light_get_metadata_record_types()%}
<hr>
{% for record_type in record_types %}
    <p style="font-size: larger;">{{h.traffic_light_get_record_type_label(record_type)}}</p> (internal schema name: {{record_type}}) 
    <br>
    <br>
    <table class="table table-striped table-bordered table-condensed">
        <tr>
            <th>Field Label</th>
            <th>Internal Field Name</th>
            <th>Weight</th>
        </tr>
    {% for field in h.traffic_light_get_evaluated_metadata_record_fields(record_type) %}
        <tr>
            <td>{{h.traffic_light_get_field_label(record_type, field)}}</td>
            <td>{{field}}</td>
            <td>
                {% if h.traffic_light_apply_weights() %}
                {{h.traffic_light_get_weight(record_type, field)}}
                {% else %}
                -
                {% endif %}
            </td>
        </tr>
    {% endfor %}
    </table>
    <hr>
{% endfor %}
...
```