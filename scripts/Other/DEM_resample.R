################################################################################
# This script takes the DEM data from NED, reprojects and resamples to
# the correct projection, and saves to a file
# 
# Author: Micah Wright
# Date: 06/07/2018
################################################################################

# Setup: Load the necessary packages
library(raster)
library(gdalUtils)
library(rgdal)

# load the raster from UW to use as a template
UW_FCID <- raster("data/UW/UW_FCID.tif")

# create a function that resamples the raster to match the template raster, and 
# saves to a file
resampleFun <- function(master, infile, outfile){
        master_crs <- as.character(crs(master))
        master_ext <- bbox(extent(master))
        master_tr <- res(master)
        
        gdalwarp(infile,
                 outfile,
                 tr = master_tr,
                 r = "near",
                 t_srs = master_crs,
                 te = master_ext,
                 overwrite = TRUE)
}


# run the function
resampleFun(UW_FCID, 
            "data/Other/DEM/dem_dev_2g.tif", 
            "data/Other/DEM/dem_dev_2g_NAD83.tif")
