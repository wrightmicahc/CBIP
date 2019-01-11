################################################################################
# This script masks the FCID raster to exclude wilderness areas as part of the
# California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load the necessary packages
library(sf)
library(raster)
library(fasterize)

# load tiles
FCID2018 <- raster("data/UW/UW_FCID.tif")

# load CA shapefile
CA <- st_read("data/Other/srtm_1_deg/srtm_1_deg_dissolve.shp",
              quiet = TRUE)

# reproject CA
CA <- st_transform(CA,
                   crs(FCID2018)@projargs)

# rasterize the CA polygon
CA_raster <- fasterize(CA, FCID2018)

# mask out Oregon in the FCID raster
FCID2018_no_OR <- mask(FCID2018, 
                       CA_raster, 
                       maskvalue = NA, 
                       datatype = dataType(FCID2018))

# remove CA 
rm(CA)
rm(CA_raster)

# load CA wilderness areas, taken from figshare
wilderness <- st_read("data/Other/wilderness/Wilderness_Areas_CA.shp", 
                      quiet = TRUE)

# reproject wilderness
wilderness <- st_transform(wilderness,
                           crs(FCID2018)@projargs)

# rasterize the wilderness polygons
wild_raster <- fasterize(wilderness, FCID2018)

# mask out wilderness in the FCID raster
FCID2018_no_wild <- mask(FCID2018_no_OR, 
                         wild_raster, 
                         maskvalue = 1, 
                         datatype = dataType(FCID2018))

# compare output to original
stk <- stack(FCID2018, FCID2018_no_wild)

samp <- sampleRandom(stk, 200, na.rm = FALSE, cells = TRUE)

# save the output
writeRaster(FCID2018_no_wild,
            "data/UW/UW_FCID_no_wild.tif",
            format = "GTiff",
            datatype = dataType(FCID2018))
