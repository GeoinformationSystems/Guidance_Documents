# Schema Reference

The following tables serve as reference to find the IDs that are used to access the metadata fields from the API. Expected Input describes in which form the according field expects the input to be. Expected datatypes that are marked as _complex_ require stringified JSON, to infer the correct structure please review the JSON representation of an existing dataset (e.g.: https://geokur-dmp.geo.tu-dresden.de/dataset/potyield) or create an according test dataset.

## Dataset Scheme

<!-- <style>
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
</style> -->
| Key | Title | Expected Input | Help Text
|:--------- |:---------| :----------|:--------|
|title|Title|String||
|name|Identifier|String||
|notes|Description|String||
|documentation|Documentation|String containing a valid URL|eg. link to publication|
|contact_name|Contact Point|String||
|contact_uri|Contact Point - ORCID|String containing a valid URL|According ORCID as link, leave blank otherwise|
|alternate_identifier|Dataset DOI|String containing a valid URL|e.g. https://doi.org/10.7283/T5MW2F2D|
|url|Information Website|String containing a valid URL|links to project website or dataset's page|
|tag_string|Keywords|_complex_||
|theme|Theme / Category|String containing one or more valid URLs that are comma separated.|Provide links to descriptions of the themes; separate by comma. E.g.: http://inspire.ec.europa.eu/theme/ad, http://inspire.ec.europa.eu/theme/au.|
|spatial|Spatial Coverage|_complex_|Draw and edit the dataset extent as rectangles on the map, or paste a GeoJSON Polygon or Multipolygon geometry below, or create a bounding box from coordinates|
|conforms_to|Coordinate Reference System|String containing a valid URL|Provide link to OGC definition of the CRS, http://docs.opengeospatial.org/DRAFTS/18-058.html#_crs_identifier_list, e.g. http://www.opengis.net/def/crs/EPSG/0/4326|
|spatial_resolution|Spatial Resolution|Value as String|Spatial Resolution (the unit is determined by the resolution type)|
|spatial_resolution_type|Spatial Resolution Measured|String; one of _"angular"_, _"scale"_ or _"meters"_|In meters: This property refers to the minimum spatial separation resolvable in a Dataset, measured in metres. As angular scale: Spatial resolution expressed as equivalent scale [ISO-19115], [ISO-19115-1], by using a representative fraction (e.g., 1:1,000, 1:1,000,000). As angular distance: Spatial resolution expressed as angular distance [ISO-19115-1], by using a decimal degree. As vertical distance: Spatial resolution expressed as vertical distance [ISO-19115-1].|
|temporal_start|Temporal Coverage Start|String; date formatted as "YYYY-MM-DD"||
|temporal_end|Temporal Coverage End|String; date formatted as "YYYY-MM-DD"||
|temporal_resolution|Temporal Resolution|String|E.g. 'P2Y3M20D' describes a period 2 years, 3 months and 20 days or 'P1D' describes a period of 1 day|
|quality_metrics|Data Quality Metric|_complex_|Value of quality metric: Measured Value of the selected quality metric \| Ground Truth Dataset: Link to ground truth dataset \| Confidence term: Label of the confidence value of the selected quality metric, e.g. r value \| Confidence value: According confidence threshold \| Thematic representativity: Describes thematic aspects for which quality information is given \| Spatial representativity: Describes region for which quality information is given \| Temporal representativity: Describes time step or range for which quality information is given \| Name of quality source: Name of the source of information of the selected quality metric \| Type of quality source: Describes the origin of the quality information: data, report, scientific publication, Web site, other \| Link to quality source: Web link to access the quality information source|
|is_version_of|Is Version of|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|A related resource of which the described resource is a version, edition, or adaptation. Changes in version imply substantive changes in content rather than differences in format.|
|is_part_of|Is Part of|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|A related resource in which the described resource is physically or logically included (https://dublincore.org/specifications/dublin-core/dcmi-terms/#isPartOf).|
|was_derived_from|Was derived from|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|Please specify datasets.|
|owner_org|Organization|String; has to match an existing organizations ID in the CKAN instance||
|license_id|Dataset License|String|Recommended best practice is to identify the license using a URI. Examples of such licenses can be found at http://creativecommons.org/licenses/.|

## Process Scheme

| Key | Title | Expected Input | Help Text
|:--------- |:---------| :----------|:--------|
|title|Title|String||
|name|Identifier|String||
|notes|Description|String|Describe the core characteristics.|
|documentation|Documentation|String containing a valid URL|Reference a documentation resp. related publication.|
|used|Used|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|Please specify input datasets.|
|generated|Generated|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|Please specify output datasets.|
|category|Category|List of Strings; Strings have to match preset values|Please categorize the process|
|owner_org|Organization|String; has to match an existing organizations ID in the CKAN instance||

## Workflow Scheme

| Key | Title | Expected Input | Help Text
|:--------- |:---------| :----------|:--------|
|title|Title|String||
|name|Identifier|String||
|notes|Description|String|Describe the core characteristics.|
|documentation|Documentation|String containing a valid URL|Reference a documentation resp. related publication.|
|source_code|Source code|String containing a valid URL|Reference the related source code, e.g. link to GitHub or Zenodo folder.|
|rel_datasets|Related datasets|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|Please specify related datasets.|
|result|Result|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|Please specify output datasets.|
|rel_processes|Related processes|String containing one or more valid URLs that are comma separated. The URLs should point to a dataset|Please select all processes that are included in the worklow.|
|owner_org|Organization|String; has to match an existing organizations ID in the CKAN instance||