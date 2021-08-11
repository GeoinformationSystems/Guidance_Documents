# --- To run this example you need to be registered as editor of an
# organization in the GeoKur CKAN.

# Load required packages
if (!require("ckanr")) install.packages("ckanr")
library("ckanr")
if (!require("raster")) install.packages("raster")
library("raster")
if (!require("rgdal")) install.packages("rgdal")
library("rgdal")

# Configure CKAN connection
ckanr_setup("https://geokur-dmp.geo.tu-dresden.de/", key = "***")

# Set some useful variables for later
dataset_base_url <- "https://geokur-dmp.geo.tu-dresden.de/dataset/"
process_base_url <- "https://geokur-dmp.geo.tu-dresden.de/process/"
workflow_base_url <- "https://geokur-dmp.geo.tu-dresden.de/workflow/"

# ----------------------------------------------------------------------------

# browse ckan available datasets, package list gives the human-readable identifieres of every public dataset. The API refers to those human-readable identifieres as "name". In the CKAN Webpage we call them "Identifier" (see reference at the bottom).
ckan_available_datasets <- package_list()

# access the metadata of a given dataset by its "name"
# package_show returns an R List object
pollination_metadata <- package_show("demand-and-supply-of-pollination-in-the-european-union-test")

# view specific metadata fields
pollination_metadata$id
pollination_metadata$name

# view all fields and attached resources
str(pollination_metadata)

# ignore resource list in view
str(pollination_metadata, max.level = 1)

# view attached resources
str(pollination_metadata$resource)

# view name, download url and id of each attached resource (only 1 resource in this case)
for (resource in pollination_metadata$resource) {
  str(resource$name)
  str(resource$url)
  str(resource$id)
}

# get resource download url (target resource is nb. 1 in resource list)
target_index <- 1
download_url_pollination <- pollination_metadata$resource[[target_index]]$url

# you can also access the resources url directly by using an api request
download_url_pollination_ <- resource_show(id = "eeecaa00-4da4-4022-9ae6-8a7849e9d5c1")$url

# ----------------------------------------------------------------------------

# Download raster from CKAN and parse it to an R Object called pollination
pollination <- raster(download_url_pollination)

# reproject the raster to WGS84
pollination_reprojected <- projectRaster(pollination, crs = "+proj=longlat +datum=WGS84 +no_defs")

# create new Metadata DS in CKAN and store it in an R object (dataset_reprojected_metadata).

# !! owner_org and contact_name are mandatory; fill with your name and your organizations
# name//id. Get all registered organizations and their names//ids with organization_list()
pollination_reprojected_metadata <- package_create(
  extras = c(
    type = "dataset",
    name = "dataset_pollination_reprojected",
    title = "Dataset Pollination Reprojected",
    conforms_to = "http://www.opengis.net/def/crs/OGC/1.3/CRS84",
    owner_org = "...",
    contact_name = "...",
    was_derived_from = paste0(
      dataset_base_url, pollination_metadata$id
    )
  )
)

yield_rapeseed_metadata <- package_show("rapeseed-yield")
yield_rapeseed <- raster(yield_rapeseed_metadata$resource[[1]]$url)

pollination_resampled <- resample(pollination_reprojected, yield_rapeseed)
pollination_resampled_metadata <- package_create(
  extras = c(
    type = "dataset",
    name = "dataset_pollination_resampled",
    title = "Dataset Pollination Resampled",
    conforms_to = "http://www.opengis.net/def/crs/OGC/1.3/CRS84",
    owner_org = "...",
    contact_name = "...",
    was_derived_from = paste(
      paste0(dataset_base_url, pollination_reprojected_metadata$id),
      paste0(dataset_base_url, yield_rapeseed_metadata$id),
      sep = ","
    )
  )
)

# ----------------------------------------------------------------------------

reproject_metadata <- package_create(
  extras = c(
    type = "process",
    name = "reproject_pollination",
    title = "Reproject Pollination",
    owner_org = "...",
    contact_name = "...",
    used = paste0(dataset_base_url, pollination_metadata$id),
    generated = paste0(dataset_base_url, pollination_reprojected_metadata$id),
    category = "geokur:Transformation"
  )
)


resample_metadata <- package_create(
  extras = c(
    type = "process",
    name = "resample_pollination",
    title = "Resample Pollination",
    owner_org = "...",
    contact_name = "...",
    used = paste(
      paste0(dataset_base_url, yield_rapeseed_metadata$id),
      paste0(dataset_base_url, pollination_reprojected_metadata$id),
      sep = ","
    ),
    generated = paste0(dataset_base_url, pollination_resampled_metadata$id),
    category = "geokur:Transformation"
  )
)

# ----------------------------------------------------------------------------

# combine pollination and yield data  to table
output_table <- cbind(as.data.frame(yield_rapeseed), as.data.frame(pollination_resampled))
names(output_table) <- c("yieldRapeseed", "pollination")
# remove 0 yields and NAs
output_table_final <- output_table[which(output_table$yield_rapeseed > 0 & !is.na(output_table$pollination)), ]

final_dataset_metadata <- package_create(
  extras = c(
    name = "rapeseed_yield_and_pollination",
    title = "Rapeseed Yield and Pollination",
    conforms_to = "http://www.opengis.net/def/crs/OGC/1.3/CRS84",
    notes = "Combined rapeseed yield and pollination as CSV",
    owner_org = "...",
    contact_name = "..."
  )
)

cbind_metadata <- package_create(
  extras = c(
    type = "process",
    name = "combine_rapeseed_and_pollination",
    title = "Combine Rapeseed And Pollination",
    notes = "Bind rapeseed yield and pollination rasters to common table and remove rapeseed values equal to zero and pollination values that are not defined.",
    owner_org = "...",
    contact_name = "...",
    used = paste(
      paste0(dataset_base_url, yield_rapeseed_metadata$id),
      paste0(dataset_base_url, pollination_resampled_metadata$id),
      sep = ","
    ),
    generated = paste0(dataset_base_url, final_dataset_metadata$id),
    category = "geokur:Selection"
  )
)

# ----------------------------------------------------------------------------

workflow_metadata <- package_create(
  extras = c(
    type = "workflow",
    name = "combine_rasters",
    title = "Combine Rasters",
    notes = "Combine rasters with different projections and resolutions in a common table",
    owner_org = "...",
    contact_name = "...",
    rel_datasets = paste(
      paste0(dataset_base_url, yield_rapeseed_metadata$id),
      paste0(dataset_base_url, pollination_metadata$id),
      paste0(dataset_base_url, pollination_resampled_metadata$id),
      paste0(dataset_base_url, pollination_reprojected_metadata$id),
      sep = ","
    ),
    rel_processes = paste(
      paste0(process_base_url, reproject_metadata$id),
      paste0(process_base_url, resample_metadata$id),
      paste0(process_base_url, cbind_metadata$id),
      sep = ","
    ),
    result = paste0(dataset_base_url, final_dataset_metadata$id)
  )
)

# ----------------------------------------------------------------------------

# add crs entry to list
pollination_resampled_metadata$conforms_to <- "http://www.opengis.net/def/crs/OGC/1.3/CRS84"

# remove some CKAN default fields that are not in our scheme and cause errors
pollination_resampled_metadata[which(names(pollination_resampled_metadata) %in% c("author_email", "maintainer_email"))] <- NULL

# pass all metadata as list(->unclass) to package_update()
package_update(unclass(pollination_resampled_metadata), pollination_resampled_metadata$id)

# ----------------------------------------------------------------------------

# store our result locally
write.csv(output_table_final, "result.csv")

# upload resource
resource_metadata <- resource_create(
  package_id = final_dataset_metadata$id,
  name = "rapeseed_and_poll_resource",
  upload = "./result.csv",
  rcurl = "https://geokur-dmp.geo.tu-dresden.de/dataset"
)

# ----------------------------------------------------------------------------

# destroy everything that was built
package_delete(pollination_reprojected_metadata$id)
package_delete(pollination_resampled_metadata$id)
package_delete(final_dataset_metadata$id)
package_delete(reproject_metadata$id)
package_delete(resample_metadata$id)
package_delete(cbind_metadata$id)
package_delete(workflow_metadata$id)