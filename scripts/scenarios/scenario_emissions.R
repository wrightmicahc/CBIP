################################################################################
# This script uses the scenario and tile number to calculate wildfire emissions
# at 25 year timesteps over a 100 year period. This is part of the CA Biopower 
# Impact Project.
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

# source function for adding rx residues back to recovered fuelbed
source("scripts/Other/add_rx_residue.R")

# source function for adding rx residues back to recovered fuelbed
source("scripts/Other/save_output.R")

library(future.apply)

plan(multiprocess)

scenario_emissions <- function(tile_number) {
        
        # create output tile folders if missing
        em_path <- "data/Tiles/output/emissions/"
        res_path <- "data/Tiles/output/residual_fuels/"
        
        lapply(c(em_path, res_path), function(x) {
                
                if(!dir.exists(paste0(x, tile_number))) {
                        dir.create(paste0(x, tile_number))
                }
        })
        
        # load scenarios
        scenarios <- fread("data/SERC/scenarios.csv", 
                           verbose = FALSE)
        
        setkey(scenarios, Silvicultural_Treatment)
        
        scenarios[, Tile_Number := tile_number]
        
        setkey(scenarios, NULL)
        
        # split the scenario dt into a list
        scenario_list <- split(scenarios, by = "ID")
        
        # decay the fuels over 100 years and save the output
        future_lapply(scenario_list, 
                      function(x) {
                              
                              ID <- x[1, ID]
                              Silvicultural_Treatment <- x[1, Silvicultural_Treatment]
                              Harvest_System <- x[1, Harvest_System]
                              Harvest_Type <- x[1, Harvest_Type]
                              Burn_Type <- x[1, Burn_Type]
                              Biomass_Collection <- x[1, Biomass_Collection]
                              Tile_Number <- x[1, Tile_Number]
                              
                              # load data
                              # this combines residue, raster, and FCCS data
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
                              
                              if(Burn_Type != "None") {
                                      
                                      # need to copy dt or it is modified 
                                      cpy <- copy(fuel_df)
                                      
                                      # calculate piled load
                                      cpy <- pile_residue(cpy, 0)
                                      
                                      # add the remaining residue to the fuelbed
                                      cpy <-  add_residue(cpy, 0)
                                      
                                      # change fire weather value names appropriately
                                      cpy[, ':=' (Wind_corrected = Wind_corrected_rx,
                                                  Fm10  = Fm10_rx,
                                                  Fm1000 = Fm1000_rx)]
                                      
                                      # apply the rx burn
                                      rx_out <- burn_residue(cpy, Burn_Type)
                                      
                                      # save the output
                                      save_output(rx_out,
                                                  Silvicultural_Treatment,
                                                  Harvest_System,
                                                  Harvest_Type,
                                                  Burn_Type,
                                                  tile_number,
                                                  Biomass_Collection,
                                                  0)
                                      
                                      # create a vector from 25-100 years
                                      timestep <- seq(25, 100, 25)
                                      
                                      # assign the vector names, otherwise position will be 
                                      # off by 1 from the value
                                      names(timestep) <- as.character(timestep)
                                      
                                      # calculate the remaining fuel for each timestep and
                                      # add to the fuelbed
                                      lapply(timestep, function(i) {
                                              
                                              # create post RX recovered fuelbed for year i
                                              post_rx <- add_rx_residue(rx_out, fuel_df, i)
                                              
                                              # change fire weather value names appropriately
                                              post_rx[, ':=' (Wind_corrected = Wind_corrected_97,
                                                              Fm10  = Fm10_97,
                                                              Fm1000 = Fm1000_97)]
                                              
                                              # burn it with wildfire
                                              output_df <- burn_residue(post_rx, "None")
                                              
                                              # save the output
                                              save_output(output_df,
                                                          Silvicultural_Treatment,
                                                          Harvest_System,
                                                          Harvest_Type,
                                                          Burn_Type,
                                                          tile_number,
                                                          Biomass_Collection,
                                                          i)
                                              
                                      })
                                      
                              } else {
                                      
                                      # create a vector from 0-100 years
                                      timestep <- seq(0, 100, 25)
                                      
                                      # assign the vector names, otherwise position will be 
                                      # off by 1 from the value
                                      names(timestep) <- as.character(timestep)
                                      
                                      # calculate the remaining fuel for each timestep and
                                      # add to the fuelbed
                                      lapply(timestep, function(i) {
                                              
                                              # need to copy dt or it is modified 
                                              cpy <- copy(fuel_df)
                                              
                                              # calculate piled load
                                              cpy <- pile_residue(cpy, i)
                                              
                                              # add the remaining residue to the fuelbed
                                              cpy <-  add_residue(cpy, i)
                                              
                                              # change fire weather value names appropriately
                                              cpy[, ':=' (Wind_corrected = Wind_corrected_97,
                                                          Fm10  = Fm10_97,
                                                          Fm1000 = Fm1000_97)]
                                              
                                              # burn it
                                              output_df <- burn_residue(cpy, Burn_Type)
                                              
                                              # save the output
                                              save_output(output_df,
                                                          Silvicultural_Treatment,
                                                          Harvest_System,
                                                          Harvest_Type,
                                                          Burn_Type,
                                                          tile_number,
                                                          Biomass_Collection,
                                                          i)
                                              
                                      })
                                      
                              }
                              
                      })
}
