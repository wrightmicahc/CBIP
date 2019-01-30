################################################################################
# This script crops the slope raster to the same extent as everything else and
# saves to a file
# 
# Author: Micah Wright
################################################################################

# Setup: Load the necessary packages
library(raster)
library(gdalUtils)
library(rgdal)

gdaldem(mode = "slope", 
        input_dem = "data/Other/DEM/DEM_Mosaic.tif", 
        output = "data/Other/DEM/Slope.tif", 
        of = "GTiff", 
        p = TRUE,
        output_Raster=TRUE)

# load the raster from UW to use as a template
UW_FCID <- raster("data/UW/UW_FCID.tif")

# load the slope raster that was just created
Slope <- raster("data/Other/DEM/Slope.tif")

# compare CRS
compareCRS(UW_FCID, Slope, verbose = TRUE)
# crop the slope raster
#Slope <- crop(Slope, extent)

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
            "data/Other/DEM/Slope.tif", 
            "data/Other/DEM/Slope_NAD83.tif")
