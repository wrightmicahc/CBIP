################################################################################
# This script loads the raster data, crops to each tile, and outputs a single
# data frame as part of the California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# source the raster list function
source("scripts/scenarios/get_raster_list.R")

# load the necessary packages
library(raster)
library(data.table)
library(parallel)

# raster file paths
raster_path_RX <- get_raster_list("Pile")
raster_path_WF <- get_raster_list("None")

# function to load and crop raster to tile
get_raster_fun <- function(x, poly){
        r <- raster(x)
        rc <- crop(r, poly)
        return(rc)
}

tiles <- sf::st_read("data/Tiles/clipped_tiles/clipped_tiles.shp",
                     quiet = TRUE)

# split tiles
tile_list <- split(tiles, tiles$ID)

# remove full tile polygon
rm(tiles)

# make a dt and save it for each tile
mclapply(tile_list,
         mc.cores = detectCores() - 1,
         function(x) { 
                 
                 rlist <- lapply(raster_path_WF, 
                                 function(i) {
                                         
                                         get_raster_fun(i, x)
                                         
                                 })
                 
                 rstack <- stack(rlist)
                 
                 rdf <- as.data.frame(rstack, 
                                      xy = TRUE,
                                      na.rm = TRUE) 
                 
                 rdf <- as.data.table(rdf)
                 
                 saveRDS(rdf,
                         file = paste0("data/Tiles/wildfire/",
                                       x$ID, 
                                       ".rds"))
                 
         })

mclapply(tile_list,
         mc.cores = detectCores() - 1,
         function(x) { 
                 
                 rlist <- lapply(raster_path_RX, 
                                 function(i) {
                                         
                                         get_raster_fun(i, x)
                                         
                                 })
                 
                 rstack <- stack(rlist)
                 
                 rdf <- as.data.frame(rstack, 
                                      xy = TRUE,
                                      na.rm = TRUE) 
                 
                 rdf <- as.data.table(rdf)
                 
                 saveRDS(rdf, 
                         file = paste0("data/Tiles/rx/",
                                       x$ID, 
                                       ".rds"))
                 
         })
