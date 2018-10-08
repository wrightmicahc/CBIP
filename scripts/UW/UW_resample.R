################################################################################
# This script takes the 30m FCID raster from UW and resamples to a larger 
# resolution, resamples the raster, creates a polygon, and saves to a file for
# use in make_tiles.R
# 
# Author: Micah Wright
################################################################################

# Setup: Load the necessary packages
library(raster)
library(gdalUtils)
library(rgdal)

# load the raster from UW to use as a template
UW_FCID <- raster("data/UW/UW_FCID.tif")

# create a function that resamples the raster using itself as a template and
# saves to a file
resampleFun <- function(master, infile, outfile, res){
        master_crs <- as.character(crs(master))
        master_ext <- bbox(extent(master))
        master_tr <- c(res, res)
        
        gdalwarp(infile,
                 outfile,
                 tr = master_tr,
                 r = "mode",
                 t_srs = master_crs,
                 te = master_ext,
                 overwrite = TRUE)
}

# run the function
resampleFun(UW_FCID, "data/UW/UW_FCID.tif", "data/UW/UW_FCID_900m.tif", res = 900)

# inspect the output
# first load the resampled raster
r <- raster("data/UW/UW_FCID_900m.tif")

# check resolution
res(r)

# check number of cells
ncell(r)

# check number of cells against original
ncell(r)/ncell(UW_FCID)

# plot the output
plot(r)

# reclassify the output so all non-NA values are 1
rc <- reclassify(r, c(1, Inf, 1))

# inspect
rc

# create a polygon
rc_poly <- rasterToPolygons(rc, na.rm = TRUE, dissolve = TRUE)

# inspect
plot(rc_poly)

# save to a file
writeOGR(rc_poly,
         dsn = "data/UW", 
         layer = "UW_poly_300m", 
         driver = "ESRI Shapefile")

# delete the resampled rasters
file.remove("data/UW/UW_FCID_900m.tif")
