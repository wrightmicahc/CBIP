################################################################################
# This script selects the tiles that contain more than 10 cells 
# 
# Author: Micah Wright
################################################################################

# Setup: Load the necessary packages
library(raster)
library(rgdal)
library(parallel)

# load the raster from UW 
UW_FCID <- raster("data/UW/FCID2018_masked.tif")

# load the tiles created in make_tiles.R
tiles <- readOGR("data/Tiles/raw_tiles",
                 "raw_tiles")

# function to count number of non-na cells in a tile
get_cells_fun <- function(x, poly){
        
        rc <- crop(x, poly)
        
        rcc <- as.data.frame(rc, na.rm = TRUE) 
        
        rcc_r <- nrow(rcc)
        
        return(rcc_r)
}

# make a list of individual tiles
t_list <- split(tiles, tiles$ID)

# get the number of non-na cells in each tile, 
# return tile number if more than 10
ncell_list <- mclapply(t_list,
                       mc.cores = detectCores(),
                       function(i){
                               
                               tile_rows <- get_cells_fun(UW_FCID, i)
                               
                               tile_id <- ifelse(tile_rows >= 10,
                                                 i$ID,
                                                 NA)
                               return(tile_id)
                       })

# unlist
full_list <- unlist(ncell_list)

# check
table(is.na(full_list))

# get good tile id numbers
good_id <- full_list[!is.na(full_list)]

# select good tiles
good_tiles <- tiles[tiles$ID %in% good_id, ]

# update ID 
good_tiles$ID <- 1:nrow(good_tiles)

# save to a file
shapefile(good_tiles, 
          filename = "data/Tiles/clipped_tiles/clipped_tiles.shp", 
          overwrite=TRUE)