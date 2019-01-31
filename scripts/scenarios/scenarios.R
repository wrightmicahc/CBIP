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

# source decay function
source("scripts/Other/decay_residue.R")

# source wrapper function for consumption and emissions function
source("scripts/Other/burn_residue.R")

library(parallel)

residue_scenario <- function(tile_number) {
        
        stopifnot(is.numeric(tile_number))
        
        # load scenarios
        scenarios <- fread("data/SERC/scenarios.csv", 
                           verbose = FALSE)
        
        setkey(scenarios, Silvicultural_Treatment)
        
        scenarios[, Tile_Number := tile_number]
        
        setkey(scenarios, NULL)
        
        # split the scenario dt into a list
        scenario_list <- split(scenarios, by = "ID")
        
        # load data
        # this combines residue, raster, and FCCS data
        emissions_list <- mclapply(scenario_list, 
                                   mc.cores = detectCores(),
                                   function(x) {
                                           
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
                                           
                                           # create a vector from 0-100 years
                                           timestep <- seq(0, 100, 1)
                                           names(timestep) <- as.character(timestep)
                                           
                                           fuel_list <- lapply(timestep, function(i) {
                                                   
                                                   # calculate piled load
                                                   fuel_df <- pile_residue(fuel_df, i)
                                                   
                                                   # add the remaining residue to the fuelbed
                                                   fuel_df <-  add_residue(fuel_df, i)
                                                   
                                                   return(fuel_df)
                                           })
                                           
                                           # save fuel
                                           saveRDS(fuel_list,
                                                   file = paste0("data/Tiles/decayed/",
                                                                 paste(tile_number, 
                                                                       Silvicultural_Treatment,
                                                                       Harvest_System,
                                                                       Harvest_Type,
                                                                       Burn_Type,
                                                                       sep = "-"),
                                                                 ".rds"))
                                           
                                           # calculate emissions
                                           output_list <- lapply(c("0", "25", "50", "75", "100"), function(i) {
                                                   try(burn_residue(fuel_list[[i]], Burn_Type))
                                                   })
                                           
                                           
                                           return(rbindlist(output_list))
                                           
                                   })
        
        output_df <- rbindlist(emissions_list)
        
        emissions_df <- output_df[, list(x, 
                                         y,
                                         fuelbed_number,
                                         FCID2018,
                                         ID, 
                                         Silvicultural_Treatment,
                                         Harvest_Type,
                                         Harvest_System,
                                         Burn_Type,
                                         Biomass_Collection, 
                                         total_char, 
                                         flaming_CH4,
                                         flaming_CO, 
                                         flaming_CO2,
                                         flaming_NH3,
                                         flaming_NOx, 
                                         flaming_PM10,
                                         flaming_PM2.5, 
                                         flaming_SO2,
                                         flaming_VOC, 
                                         smoldering_CH4, 
                                         smoldering_CO, 
                                         smoldering_CO2,
                                         smoldering_NH3,
                                         smoldering_NOx, 
                                         smoldering_PM10, 
                                         smoldering_PM2.5,
                                         smoldering_SO2, 
                                         smoldering_VOC,
                                         residual_CH4, 
                                         residual_CO, 
                                         residual_CO2,
                                         residual_NH3, 
                                         residual_NOx, 
                                         residual_PM10, 
                                         residual_PM2.5, 
                                         residual_SO2,
                                         residual_VOC, 
                                         total_CH4,
                                         total_CO, 
                                         total_CO2, 
                                         total_NH3,
                                         total_NOx,
                                         total_PM10,
                                         total_PM2.5, 
                                         total_SO2, 
                                         total_VOC)]
        
        residual_df <- output_df[, list(x, 
                                        y,
                                        fuelbed_number,
                                        FCID2018, 
                                        ID, 
                                        Silvicultural_Treatment,
                                        Harvest_Type,
                                        Harvest_System,
                                        Burn_Type,
                                        Biomass_Collection, 
                                        Slope,
                                        Fm10,
                                        Fm1000,
                                        Wind_corrected,
                                        duff_upper_loading,
                                        litter_loading, 
                                        one_hr_sound, 
                                        ten_hr_sound,
                                        hun_hr_sound,
                                        oneK_hr_sound,
                                        oneK_hr_rotten,
                                        tenK_hr_sound, 
                                        tenK_hr_rotten,
                                        tnkp_hr_sound,
                                        tnkp_hr_rotten,
                                        pile_field,
                                        pile_landing)]

        # save output
        saveRDS(emissions_df,
                file = paste0("data/Tiles/output/emissions/",
                             tile_number,
                             ".rds"))
        
        saveRDS(residual_df,
                file = paste0("data/Tiles/output/residual_fuels/",
                             tile_number,
                             ".rds"))
        
}
