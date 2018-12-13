################################################################################
# This script uses the scenario and tile number to calculate emissions from 
# wildfire as part of the CA Biopower Impact Project.
#
# tile_number: numeric tile number.
#
# Author: Micah Wright, Humboldt State University
################################################################################

# source function that loads and merges FCCS, residue, and spatial data 
source("scripts/scenarios/load_data.R")

# source function that corrects midflame windspeed
source("scripts/Other/wind_correction.R")

# source function that partitions residue into piled/unpiled
source("scripts/Other/pile_residue.R")

# source function that adds residue to FCCS fuelbeds
source("scripts/Other/add_residue.R")

# source wrapper function for consumption and emissions function
source("scripts/Other/burn_residue.R")

residue_scenario <- function(tile_number) {
        
        stopifnot(is.numeric(tile_number))
        
        # load scenarios
        scenarios <- fread("data/SERC/scenarios.csv", 
                           verbose = FALSE)
        
        setkey(scenarios, Silvicultural_Treatment)
        
        scenarios <- scenarios[!"Standing_Dead"]
        
        scenarios[, Tile_Number := tile_number]
        
        setkey(scenarios, NULL)
        
        # split the scenario dt into a list
        scenario_list <- split(scenarios, by = "ID")
        
        # load data
        # this combines residue, raster, and FCCS data
        emissions_list <- lapply(scenario_list, function(x) {
                
                ID <- x[1, ID]
                Silvicultural_Treatment <- x[1, Silvicultural_Treatment]
                Harvest_System <- x[1, Harvest_System]
                Harvest_Type <- x[1, Harvest_Type]
                Burn_Type <- x[1, Burn_Type]
                Biomass_Collection <- x[1, Biomass_Collection]
                Tile_Number <- x[1, Tile_Number]
                
                fuel_df <- load_data(ID,
                                     Silvicultural_Treatment,
                                     Harvest_System,
                                     Harvest_Type, 
                                     Burn_Type,
                                     Biomass_Collection,
                                     Tile_Number)
                
                # correct windspeed
                wind_correction(fuel_df,
                                Wind,
                                TPA,
                                TPI)
                
                # calculate piled load
                fuel_df <- pile_residue(fuel_df)
                
                # add the remaining residue to the fuelbed
                fuel_df <-  add_residue(fuel_df)
                
                # calculate emissions
                output <- try(burn_residue(fuel_df, Burn_Type))
                
                return(output)
                
        })
        
        return(rbindlist(emissions_list))
        
}
