################################################################################
# This script removes the tiles in wilderness areas as part of the California
# Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load the necessary packages
library(sf)
library(tidyverse)

# load tiles
tiles <- st_read("data/Tiles/good_tiles.shp", quiet = TRUE)

# load CA wilderness areas, taken from figshare
wilderness <- st_read("data/Other/wilderness/Wilderness_Areas_CA.shp", quiet = TRUE)

# reproject wilderness
wilderness <- st_transform(wilderness,
                             st_crs(tiles))

# select wilderness tiles
wild_tiles <- tiles[wilderness, ]

# get all tiles not in the wilderness
tiles_clip <- filter(tiles, !(ID %in% wild_tiles$ID))

# save to a file
st_write(tiles_clip, 
         "data/Tiles/clipped_tiles",
         driver = "ESRI Shapefile")
