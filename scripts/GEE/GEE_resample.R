################################################################################
# This script takes the 4km gridmet data from GEE reprojects and resamples to
# 30m resolution, and saves to a file
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

# get a list of input file names
infile <- list.files("data/GEE/raw",
                     pattern = ".tif$",
                     recursive = TRUE,
                     full.names = TRUE)

# clean out resampled folder to avoid overwrite issues
lapply(list.files("data/GEE/resampled", full.names = TRUE), file.remove)

# make a list of output file names
outfile <- paste0("data/GEE/resampled/", 
                  sub(".*/", "", infile))

# run the function
mapply(function(x, y){resampleFun(UW_FCID, x, y)}, x = infile, y = outfile)
