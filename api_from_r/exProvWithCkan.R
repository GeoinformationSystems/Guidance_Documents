## Extract and analyze data for GeoKur use case 1 (test)
# Author: Lukas Egli
# Date: 19/05/2021

#---- Load required packages
if (!require("ckanr")) install.packages("ckanr")
library("ckanr")
if (!require("raster")) install.packages("raster")
library("raster")
if (!require("rgdal")) install.packages("rgdal")
library("rgdal")


#----
## PROVENANCE (in progress)
# Testing Packages for provenance tracking --> TBD


# ----
## CONFIGURE CKAN CONNECITON
# (BEFORE making public the repository REMEMBER to remove from history the CAN API KEY)
ckanr_setup("https://geokur-dmp.geo.tu-dresden.de/", key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2MjU2NjM3MDUsImp0aSI6Imp3Unk0dVo5cThfbVhBUnRYXzl4VlYwRmZ3SVVMS2dVTkV0UFVhR2VuZlJ2TVQ5T2ZKNTF3ZzI4b0ZqaXRTeFlSODRQbmFwRVRiejFlRmFmIn0.Bf1S8NPlhlQVhJdU_6kN1nqGq6lAgzSnYzg96-nIFd0")


dataset_base_url <- "https://geokur-dmp.geo.tu-dresden.de/dataset/"
process_base_url <- "https://geokur-dmp.geo.tu-dresden.de/process/"
workflow_base_url <- "https://geokur-dmp.geo.tu-dresden.de/workflow/"

# browse ckan available datasets, package list gives the human-readable identifieres of every public dataset. The API refers to those human-readable identifieres as
# "name". In the CKAN Webpage we call them "Identifier".
ckan_available_datasets <- package_list()

# access the metadata of a given dataset by its "name"
# package_show returns an R List object
pollination_metadata <- package_show("demand-and-supply-of-pollination-in-the-european-union-test")

# view specific metadata fields
pollination_metadata$id
pollination_metadata$name

# view all fields and attached resources
# str(pollination_metadata)
# ignore resource list in view
str(pollination_metadata, max.level = 1)

# view attached resources
str(pollination_metadata$resource)

# view names and download urls of all attached resources (here this is only 1 resource)
for (resource in pollination_metadata$resource) {
  str(resource$name)
  str(resource$url)
  # view id as well
  str(resource$id)
}

# get resource download url (target resource is nb. one in resource list)
target_index <- 1
download_url_pollination <- pollination_metadata$resource[[target_index]]$url

# you can also access the resources url directly by using an api request
download_url_pollination_ <- resource_show(id = "eeecaa00-4da4-4022-9ae6-8a7849e9d5c1")$url

# of course the url can also be found by carefully looking into pollination_metadata

# ----
## LOAD LOCALLY REMOTE RESOURCE (FROM CKAN)
pollination <- raster(download_url_pollination)

# do the same for rapeseed
yieldRapeseed_metadata <- package_show("rapeseed-yield")
yieldRapeseed <- raster(resource_show(id = "945acf8d-925f-44c5-8f45-4b6354f1734d")$url)



# ########################## DATA PREPROCESSING

# # project raster
pollinationProj <- projectRaster(pollination, crs = "+proj=longlat +datum=WGS84 +no_defs ") # change crs
# ---- CREATE INTERMEDIATE DATASET 1 ----
# "name" Must be purely lowercase alphanumeric (ascii) characters and these symbols: -_
# -> reason is that the name resolves to a URI.
# was derived from accepts only full urls of datasets, this way it can be linked to datasets
# that are not part of the ckan
intermediate_dataset_pollination_proj <- package_create(
  extras = c(
    type = "dataset",
    name = "dataset_pollination_reprojeced",
    title = "Dataset Pollination Reprojected",
    conforms_to = "http://www.opengis.net/def/crs/OGC/1.3/CRS84",
    owner_org = "ufz",
    contact_name = "lukas",
    was_derived_from = paste0(dataset_base_url, pollination_metadata$id)
  )
)
# at this point we could also upload the reprojected resource 
# (this is desrcibed at the end of the doc)

# # resample to 5 arcmin
pollinationRes <- resample(pollinationProj, yieldRapeseed)
# ---- CREATE INTERMEDIATE DATASET 2 ----
intermediate_dataset_pollination_res <- package_create(
  extras = c(
    name = "dataset_pollination_resampled",
    title = "Dataset Pollination Resampled",
    owner_org = "ufz",
    contact_name = "lukas",
    was_derived_from = paste(
      paste0(dataset_base_url, yieldRapeseed_metadata$id),
      paste0(dataset_base_url, intermediate_dataset_pollination_proj$id),
      sep = ","
    )
  )
)

# we could also upload these plos as resources
plot(pollinationRes, xlim = c(-20, 50), ylim = c(20, 70))
plot(yieldRapeseed, xlim = c(-20, 50), ylim = c(20, 70))


# combine pollination and yield data  to table
outputTable <- cbind(as.data.frame(yieldRapeseed), as.data.frame(pollinationRes))
names(outputTable) <- c("yieldRapeseed", "pollination")
# remove 0 yields and NAs
outputTableFinal <- outputTable[which(outputTable$yieldRapeseed > 0 & !is.na(outputTable$pollination)), ]
head(outputTableFinal) ## this would be the DATA OUTPUT!

write.csv(outputTableFinal,"result.csv")


# further define processes
reproject_metadata <- package_create(
  extras = c(
    type = "process",
    name = "reproject-pollination",
    title = "Reproject Pollination",
    owner_org = "ufz",
    contact_name = "lukas",
    used = paste0(dataset_base_url, pollination_metadata$id),
    generated = paste0(dataset_base_url, intermediate_dataset_pollination_proj$id),
    category = "geokur:Transformation"
  )
)

# further define processes
resample_metadata <- package_create(
  extras = c(
    type = "process",
    name = "resample-pollination",
    title = "Resample Pollination",
    owner_org = "ufz",
    contact_name = "lukas",
    used = paste(
      paste0(dataset_base_url, yieldRapeseed_metadata$id),
      paste0(dataset_base_url, intermediate_dataset_pollination_proj$id),
      sep = ","
    ),
    generated = paste0(dataset_base_url, intermediate_dataset_pollination_res$id),
    category = "geokur:Transformation"
  )
)

# if a ds was derived form multiple other ds; their urls have to be provided as comma separeted string
# # ---- CREATE OUTPUT DATASET ----
output_dataset <- package_create(
  extras = c(
    name = "rapeseed-yield-and-pollination",
    title = "Rapeseed Yield and Pollination",
    conforms_to = "http://www.opengis.net/def/crs/OGC/1.3/CRS84",
    notes = "Combined rapeseed yield and pollination as CSV",
    owner_org = "ufz",
    contact_name = "lukas"
  )
)

cbind_metadata <- package_create(
  extras = c(
    type = "process",
    name = "combine-rapeseed-and-pollination",
    title = "Combine Rapeseed And Pollination",
    owner_org = "ufz",
    contact_name = "lukas",
    used = paste(
      paste0(dataset_base_url, yieldRapeseed_metadata$id),
      paste0(dataset_base_url, intermediate_dataset_pollination_res$id),
      sep = ","
    ),
    generated = paste0(dataset_base_url, output_dataset$id),
    category = "geokur:Selection"
  )
)

workflow_metadata <- package_create(
  extras = c(
    type = "workflow",
    name = "combine-rasters",
    title = "Combine Rasters",
    notes = "Combine rasters with differnent projections and resolutions in a common table",
    owner_org = "ufz",
    contact_name = "lukas",
    rel_datasets = paste(
      paste0(dataset_base_url, yieldRapeseed_metadata$id),
      paste0(dataset_base_url, pollination_metadata$id),
      paste0(dataset_base_url, intermediate_dataset_pollination_res$id),
      paste0(dataset_base_url, intermediate_dataset_pollination_proj$id),
      sep = ","
    ),
    rel_processes = paste(
      paste0(process_base_url, reproject_metadata$id),
      paste0(process_base_url, resample_metadata$id),
      paste0(process_base_url, cbind_metadata$id),
      sep = ","
    ),
    result = paste0(dataset_base_url, output_dataset$id)
  )
)

# update metadata
# get metadata if not in df already 
# (we stored resample_metadata at the datasets creation)


pollination_resampled <- package_show('dataset_pollination_resampled')
pollination_resampled[which(names(pollination_resampled)%in%c("relationships_as_object","relationships_as_subject","organization", "tags", "groups", "resources"))] <- NULL

package_patch(pollination_resampled, extras=c(conforms_to= "http://www.opengis.net/def/crs/OGC/1.3/CRS84"))


# CAREFUL! Do not delete the input datasets by accident (I did this)

package_delete(pollination_resampled$id)
# package_delete(id = intermediate_dataset_pollination_res$name)
# package_delete(id = output_dataset$name)
final <- package_show("rapeseed-yield-and-pollination")


# #----
# ## CREATE RESOURCE (outputTableFinal) & PUSH IT TO CKAN --> UPDATE PACKAGE
#file <- system.file("table", table, package = "ckanr")/
resource_metadata <- resource_create(package_id = final$id,
                        name = "rapeseed_and_poll_resource",
                        upload = "./result.csv",
                        rcurl = "https://geokur-dmp.geo.tu-dresden.de/dataset"
)


pollination_reprojected_metadata <- package_show("dataset_pollination_reprojeced")
pollination_resampled_metadata <- package_show("dataset_pollination_resampled")
final_dataset_metadata <- package_show("rapeseed-yield-and-pollination")
reproject_metadata <- package_show("reproject-pollination")
resample_metadata <- package_show("resample-pollination")
cbind_metadata <- package_show("combine-rapeseed-and-pollination")
workflow_metadata <- package_show("combine-rasters")


package_delete(pollination_reprojected_metadata$id)
package_delete(pollination_resampled_metadata$id)
package_delete(final_dataset_metadata$id)
package_delete(reproject_metadata$id)
package_delete(resample_metadata$id)
package_delete(cbind_metadata$id)
package_delete(workflow_metadata$id)

# #----
# ## CREATE RESOURCE (outputTableFinal) & PUSH IT TO CKAN --> UPDATE PACKAGE
# #file <- system.file("examples", outputTableFinal, package = "ckanr")
# (xx <- resource_create(package_id = res$id,
#                        description = "mymyOutputTableFinal  resource",
#                        name = "myOutputTableFinal",
#                        upload = "./myOutputTable.csv",
#                        rcurl = "https://geokur-dmp.geo.tu-dresden.de/dataset"
# ))

# ## CREATE RESOURCE (LinearModelOutput) & PUSH IT TO CKAN --> UPDATE PACKAGE
# (xx <- resource_create(package_id = res$id,
#                        description = "my LinearModelOutput resource",
#                        name = "LinearModelOutput",
#                        upload = "./LinearModelOutput.txt",
#                        rcurl = "https://geokur-dmp.geo.tu-dresden.de/dataset"
# ))


# #ds_create(resource_id = xx$id, records = iris, force = TRUE)
# resource_show(xx$id)


# rm(list=ls())