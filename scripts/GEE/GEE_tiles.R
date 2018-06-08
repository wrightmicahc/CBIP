################################################################################
# This script tiles the 30m gridmet data created in GEE_resample.R to 1km and 
# saves to file
# 
# Author: Micah Wright
# Date: 06/07/2018
################################################################################

# Setup: Load the necessary packages
library(raster)
library(gdalUtils)
library(rgdal)

# load the 30m GEE data
bigstack <- stack(list.files("data/GEE/temp",
                             pattern = ".tif$",
                             full.names = TRUE))

# Load the 1 degree SRTM files to use as tiles
tiles <- readOGR("data/other/srtm_1_deg",
                 "srtm_1_deg")

# Convert the crs to match the stack  
tiles <- spTransform(tiles, crs(bigstack))

# Split tiles into a list based on degree
tiles <- split(tiles, tiles$id)

# Crop the stack to each tile
tile_list <- lapply(tiles, function(x) raster::crop(bigstack, x))

# Remove any previously saved files to avoid overwrite issues
lapply(list.files("data/GEE/tiles", full.names = TRUE), file.remove)

# Write the tiled mutliband stack to seperate files, named for each of the 1 
# degree tiles
lapply(1:length(tile_list), function(i){ 
        raster::writeRaster(tile_list[[i]], 
                            filename = paste0("data/GEE/tiles/", 
                                              names(tile_list[i]), 
                                              ".tif"),
                            options = "INTERLEAVE=BAND")})

# Remove temp files 
lapply(list.files("data/GEE/temp", full.names = TRUE), file.remove)
