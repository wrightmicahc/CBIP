################################################################################
# This script loads the raster data, crops to each tile, and outputs a single
# data frame as part of the California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load the necessary packages
library(raster)
library(data.table)
library(parallel)


# raster file paths
raster_paths <- list("FCID2018" = "data/UW/FCID2018_masked.tif",
                     "Slope" = "data/Other/DEM/Slope_NAD83.tif",
                     "fuelbed_number" = "data/FCCS/spatial/FCCS_NAD83.tif", 
                     "Fm10_50" = "data/GEE/resampled/fm10_50.tif",
                     "Fm1000_50" = "data/GEE/resampled/fm1000_50.tif",
                     "Wind_50" = "data/GEE/resampled/windv_50.tif",
                     "Fm10_97" = "data/GEE/resampled/fm10_97.tif",
                     "Fm1000_97" = "data/GEE/resampled/fm1000_97.tif",
                     "Wind_97" = "data/GEE/resampled/windv_97.tif",
                     "Fm10_rx" = "data/GEE/resampled/fm10_375.tif",
                     "Fm1000_rx" = "data/GEE/resampled/fm1000_375.tif",
                     "Wind_rx" = "data/GEE/resampled/windv_375.tif",
                     "TPI" = "data/Other/DEM/dem_dev_2g_NAD83.tif",
                     "CWD_K" = "data/Other/Decay/rasters/with_cm/cwd_cm.tif",
                     "FWD_K" = "data/Other/Decay/rasters/with_cm/fwd_cm.tif",
                     "Foliage_K" = "data/Other/Decay/rasters/with_cm/foliage_cm.tif")

# function to load and crop raster to tile
get_raster_fun <- function(x, poly) {
        r <- raster(x)
        rc <- crop(r, poly)
        return(rc)
}

# load the tiles
tiles <- sf::st_read("data/Tiles/clipped_tiles/clipped_tiles.shp",
                     quiet = TRUE)

# split tiles by ID number
tile_list <- split(tiles, tiles$ID)

# remove full tile polygon
rm(tiles)

# make a dt and save it for each tile
mclapply(tile_list,
         mc.cores = detectCores(),
         function(x) { 
                 
                 rlist <- lapply(raster_paths, function(i) {
                         
                         get_raster_fun(i, x)
                         
                 })
                 
                 # stack the rasters
                 rstack <- stack(rlist)

                 rdf <- as.data.frame(rstack, 
                                      xy = TRUE,
                                      na.rm = TRUE) 
                 
                 rdf <- as.data.table(rdf)
                 
                 saveRDS(rdf,
                         file = paste0("data/Tiles/input/",
                                       x$ID, 
                                       ".rds"))
                 
         })
