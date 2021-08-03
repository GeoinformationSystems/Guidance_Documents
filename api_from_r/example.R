## Extract and analyze data for GeoKur use case 1 (test)
# Author: Lukas Egli
# Date: 19/05/2021

#---- Load required packages
if (!require("ckanr")) install.packages("ckanr");library ("ckanr")

ckanr_setup("http://172.26.62.253/", key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2MjY2OTYzNzcsImp0aSI6IlFFc3pzZXByUmtUa25iMmhETnE5UXZGZkVQVHVsQWdYbV8xZ3BnYXFQQ0Y5bWpZR1ROY1U3QWEyR0NzbmwwNHdnellXVkNfU2NHUU9JbVRIIn0.b8NwZNxrv_qsZxV-aHxxsru49HH2A6IivdN2eeSuFeE")


ckan_available_datasets <- package_create(    
    extras = c(
    type = 'process',
    name = "test-process2",
    owner_org = "rue_orga"
  )
)
