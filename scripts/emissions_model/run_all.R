################################################################################
# This script runs the scenario_emissions function on each tile. Tiles numbers
# are taken from the shapefile ID numbers. This takes many hours to run.
# 
#
# Author: Micah Wright 
################################################################################

# load sf package
library(sf)

# source the scenario_emissions function
source("scripts/emissions_model/scenario_emissions.R")

# load tile shapefile
tiles <- st_read("data/Tiles/clipped_tiles/clipped_tiles.shp")

# get the tile id numbers
tile_nums <- tiles$ID

# how many tiles?
length(tile_nums) 

# run the function on each tile
lapply(tile_nums, function(x) try(scenario_emissions(x)))
