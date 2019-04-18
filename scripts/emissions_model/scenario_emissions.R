################################################################################
# This script uses the scenario and tile number to calculate wildfire emissions
# at 25 year timesteps over a 100 year period. This is part of the CA Biopower 
# Impact Project.
#
# tile_number: numeric tile number. Must be one of the actual tile numbers
#
# Author: Micah Wright, Humboldt State University
################################################################################

# source function that loads and merges FCCS fuelbed, biomass residue, and 
# location attribute data 
source("scripts/emissions_model/load_data.R")

# source function that corrects midflame windspeed
source("scripts/emissions_model/wind_correction.R")

# source function that assigns appropriate residue into piled mass
source("scripts/emissions_model/pile_residue.R")

# source function that adds scattered residue to FCCS fuelbeds
source("scripts/emissions_model/add_residue.R")

# source decay functions
source("scripts/emissions_model/decay_residue.R")

# source wrapper function for consumption and emissions functions
source("scripts/emissions_model/burn_residue.R")

# source function for adding rx residues back to recovered fuelbed
source("scripts/emissions_model/add_rx_residue.R")

# source function for saving model output
source("scripts/emissions_model/save_output.R")

# load parallel processing package, wrapper for os agnostic future package
library(future.apply)

# assign local multicore processing if available
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
        
        # run fuel processing and decay/fire models on each scenario in the list
        # in parallel
        future_lapply(scenario_list, 
                      function(x) {
                              
                              # make sure each element of the list is a single-row
                              # data table
                              stopifnot(nrow(x) == 1)
                              
                              # assign scenario ids. x is a single-row data table,
                              # so assigning the first row gets the correct value
                              ID <- x[1, ID]
                              Silvicultural_Treatment <- x[1, Silvicultural_Treatment]
                              Burn_Type <- x[1, Burn_Type]
                              Biomass_Collection <- x[1, Biomass_Collection]
                              Pulp_Market <- x[1, Pulp_Market]
                              Tile_Number <- x[1, Tile_Number]
                              
                              # load data
                              # this combines residue, fuelbed, and spatial
                              # attribute data
                              fuel_df <- load_data(ID,
                                                   Silvicultural_Treatment,
                                                   Burn_Type,
                                                   Biomass_Collection,
                                                   Tile_Number)
                              
                              # correct windspeed from 10m to mid-flame
                              wind_correction(fuel_df,
                                              Wind,
                                              TPA,
                                              TPI)
                              
                              # RX burn scenarios
                              if(Burn_Type != "None") {
                                      
                                      # need to copy fuel_df or it is modified in place
                                      cpy <- copy(fuel_df)
                                      
                                      # calculate piled load
                                      cpy <- pile_residue(cpy, 0)
                                      
                                      # add the scattered residue to the fuelbed
                                      cpy <-  add_residue(cpy, 0)
                                      
                                      # change fire weather value names appropriately
                                      cpy[, ':=' (Wind_corrected = Wind_corrected_rx,
                                                  Fm10  = Fm10_rx,
                                                  Fm1000 = Fm1000_rx)]
                                      
                                      # apply the rx burn
                                      rx_out <- burn_residue(cpy, Burn_Type)
                                      
                                      # save the output
                                      lapply(1:2, function(i) {
                                              save_output(rx_out[[i]],
                                                          Silvicultural_Treatment,
                                                          ID,
                                                          Burn_Type,
                                                          tile_number,
                                                          Biomass_Collection,
                                                          Pulp_Market,
                                                          secondary_burn = names(rx_out)[i],
                                                          0)
                                              })
                                      
                                      # create a vector from 25-100 years in 25 year bins
                                      timestep <- seq(25, 100, 25)
                                      
                                      # assign the vector names, otherwise position will be 
                                      # off by 1 from the value
                                      names(timestep) <- as.character(timestep)
                                      
                                      # calculate the remaining fuel for each timestep and
                                      # add to the fuelbed
                                      lapply(timestep, function(i) {
                                              
                                              # create post RX recovered fuelbed for year i
                                              post_rx <- add_rx_residue(rx_out[["first"]], fuel_df, i)
                                              
                                              # change fire weather value names appropriately
                                              post_rx[, ':=' (Wind_corrected = Wind_corrected_97,
                                                              Fm10  = Fm10_97,
                                                              Fm1000 = Fm1000_97)]
                                              
                                              # burn the recovered fuelbed with wildfire
                                              output_df <- burn_residue(post_rx, "None")
                                              
                                              # save the output
                                              save_output(output_df,
                                                          Silvicultural_Treatment,
                                                          ID,
                                                          Burn_Type,
                                                          tile_number,
                                                          Biomass_Collection,
                                                          Pulp_Market,
                                                          secondary_burn = "first",
                                                          i)
                                              
                                      })
                                      # wildfire scenarios
                              } else {
                                      
                                      # create a vector from 0-100 years
                                      timestep <- seq(0, 100, 25)
                                      
                                      # assign the vector names, otherwise position will be 
                                      # off by 1 from the value
                                      names(timestep) <- as.character(timestep)
                                      
                                      # calculate the remaining fuel for each timestep,
                                      # add to the fuelbed, and burn it
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
                                                          ID,
                                                          Burn_Type,
                                                          tile_number,
                                                          Biomass_Collection,
                                                          Pulp_Market,
                                                          secondary_burn = "first",
                                                          i)
                                              
                                      })
                                      
                              }
                              
                      })
}
