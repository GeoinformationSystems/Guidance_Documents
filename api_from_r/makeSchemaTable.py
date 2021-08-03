# %%

import json

with open('dataset_geokur_live.json') as workflow_schema:
    fields = json.load(workflow_schema)['dataset_fields']
    table = []
    style = '''<style>
table th:first-of-type {
    width: 15%;
}
table th:nth-of-type(2) {
    width: 15%;
}
table th:nth-of-type(3) {
    width: 30%;
}
table th:nth-of-type(4) {
    width: 40%;
}
</style>'''
    table.append(style)
    table.append('| Key | Title | Expected Input | Help Text')
    table.append('|:--------- |:---------| :----------|:--------|')
    for field in fields:
        help_text = ''
        if 'help_text' in field.keys():
            help_text = field['help_text'].replace(
                '|', '\|').replace('\n', ' ')
        # dirty
        preset = field['preset'].replace(
            'title', 'String').replace(
            'name', 'String').replace(
            'notes', 'String').replace(
            'contact_String', 'String').replace(
            'single_link', 'String containing a valid URL').replace(
            'tags', '_complex_').replace(
            'multi_link', 'String containing one or more valid URLs that are comma separated.').replace(
            'spatial_extent', '_complex_').replace(
            'spatial_resolution_type', 'String; one of _"angular"_, _"scale"_ or _"meters"_').replace(
            'spatial_resolution', 'Value as String').replace(
            'date_range_start', 'String; date formatted as "YYYY-MM-DD"').replace(
            'date_range_end', 'String; date formatted as "YYYY-MM-DD"').replace(
            'textinput', 'String').replace(
            'select_metrics', '_complex_').replace(
            'select_dataset_by_type', 'String containing one or more valid URLs that are comma separated. The URLs should point to a dataset').replace(
            'owner_org', 'String; has to match an existing organizations ID in the CKAN instance').replace(
            'multiple_checkbox', 'List of Strings; Strings have to match preset values')
        table.append(
            '|' +
            field['field_name'] + '|' +
            field['label'] + '|' +
            preset + '|' +
            help_text + '|')
    print('\n'.join(table))
