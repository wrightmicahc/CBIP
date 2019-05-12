################################################################################
# This script runs the scenario_emissions function on each tile. Tiles numbers
# are taken from the shapefile ID numbers. This takes many hours to run 
# depending on whether or not every tile is run.
#
# t_range: range or single integer that corresponds to specific tile numbers 
# save_runtime: save runtime to .rds file? default TRUE
#
# Author: Micah Wright 
################################################################################

run_all <- function(t_range = NULL, save_runtime = TRUE) {
        # load sf package
        library(sf)
        
        # source the scenario_emissions function
        source("scripts/emissions_model/scenario_emissions.R")
        
        # load tile shapefile
        tiles <- st_read("data/Tiles/clipped_tiles/clipped_tiles.shp",
                         quiet = TRUE)
        
        # get the tile id numbers
        tile_nums <- tiles$ID
        
        # run message
        run_message <- "calculating emissions scenarios for"
        
        if(is.null(t_range)) {
                # run the function on each tile
                message(paste(run_message, length(tile_nums), "tiles..."))
                run_time <- system.time(lapply(tile_nums, function(x) try(scenario_emissions(x))))       
        } else {
                # run the function on the specified tiles
                message(paste(run_message, length(t_range), "tiles..."))
                run_time <- system.time(lapply(tile_nums[t_range], function(x) try(scenario_emissions(x))))
        }
        
        saveRDS(run_time, "run_time.rds")
        
}
