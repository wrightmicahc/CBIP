################################################################################
# This script stacks the FCID, FCCS to a single multiband image, splits the 
# image into tiles, and saves to a file
# 
# Author: Micah Wright
# Date: 06/07/2018
################################################################################

# Setup: Load the necessary packages
library(raster)
library(rgdal)
library(parallel)

# Make a list with the file names of the necessary rasters
file_list <- list("FCID2018" = "data/UW/UW_FCID.tif",
                  "Slope" = "data/Other/DEM/Slope_NAD83.tif",
                  "fuelbed_number" = "data/FCCS/spatial/FCCS_NAD83.tif", 
                  "Fm10" = "data/GEE/temp/fm10.tif",
                  "Fm1000" = "data/GEE/temp/fm1000.tif",
                  "Wind" = "data/GEE/temp/windv.tif",
                  "TPI" = "data/Other/DEM/dem_dev_2g_NAD83.tif")

# Load the rasters as a stack
rstack <- stack(file_list)

# make a function that creates a list of extents that fall within an existing 
# extent object. needs a raster and the number of tiles in the x-y dimensions
SplitRas <- function(r, numtiles_x, numtiles_y) {
        # make a master extent
        rbounds <- as.matrix(extent(r))
        
        # make a data frame with the coordinates in between current extent limits
        coord_df <- data.frame(x = seq(rbounds[1, 1], 
                                       rbounds[1, 2], 
                                       length.out = numtiles_x),
                               y = seq(rbounds[2, 1],
                                       rbounds[2, 2], 
                                       length.out = numtiles_y))
        
        # make a list of all the extents within the master extent
        ext_List <- unlist(lapply(seq(1:(nrow(coord_df)-1)), function(i)
                lapply(seq(1:(nrow(coord_df)-1)), function(j) 
                        extent(coord_df$x[i], coord_df$x[i + 1],
                               coord_df$y[j], coord_df$y[j + 1]))
                ))
        
        return(ext_List)
}

# make a bunch of extents
ext_list <- SplitRas(rstack, 25, 25)

# crop function
CropRas <- function(r, l, ex, id){
        browser()
        cr <- crop(r, ex)
        
        # fraction that is NA
        i <- cellStats(is.na(cr[[l]]), sum)/ncell(cr[[l]])
        
        if(i != 1)
               raster::writeRaster(cr, 
                                   filename = paste0("data/Tiles/", 
                                                     id, 
                                                     ".tif"),
                                   options = "INTERLEAVE=BAND")
}

# Remove any old tiles to avoid overwrite issues
lapply(list.files("data/Tiles", full.names = TRUE), file.remove)

# crop the raster to each extent
mclapply(seq(1:length(ext_list)), 
         mc.cores = detectCores()-2,
         function(i) CropRas(rstack,
                             "FCID2018",
                             ext_list[[i]],
                             i))
