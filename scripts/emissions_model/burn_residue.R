################################################################################
# This script uses the consume activity equations to estimate the fuel burned 
# and FEPS/bluesky emissions factors to estimate emissions as part of the
# California Biopower Impact Project. 
#
# dt: input data.table
# burn_type: None (wildfire), Pile, Broadcast, or Jackpot 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# source functions that calculate consumption and emissions
source("scripts/Consume/con_calc_activity_fast.R")
source("scripts/Consume/calc_emissions.R")
source("scripts/emissions_model/remove_rx_consumed.R")

burn_residue <- function(dt, burn_type) {
        
        # wildfire
        if(burn_type  == "None") {
                
                # specify diameter reduction factor
                DRR  <- 2.0 / 3.0
                
                # simulate wildfire
                consumption_df <- ccon_activity_fast(dt, 
                                                     fm_type = "NFDRS_Th",
                                                     days_since_rain = 50,
                                                     DRR = DRR,
                                                     burn_type = burn_type)
                
                # calculate emissions and residual fuels
                emissions_df <- calc_emissions(consumption_df, burn_type)
                
        }
        # RX with scattered and piled fuels
        if(burn_type  %in% c("Broadcast", "Pile and Broadcast")) {
                
                # specify diameter reduction factor
                DRR  <- 1 
                
                # simulate RX
                consumption_df <- ccon_activity_fast(dt, 
                                                     fm_type = "NFDRS_Th", 
                                                     days_since_rain = 10,
                                                     DRR = DRR, 
                                                     burn_type = burn_type)
                
                # remove consumed fuel
                burn_again <- remove_rx_consumed(consumption_df, burn_type)
                
                # update fire weather
                burn_again[,":=" (Fm10  = Fm10_97,
                                  Fm1000 = Fm1000_97,
                                  Wind_corrected = Wind_corrected_97)]
                
                # simulate wildfire
                consumption_df2 <- ccon_activity_fast(burn_again, 
                                                      fm_type = "NFDRS_Th", 
                                                      days_since_rain = 50,
                                                      DRR = 2.0 / 3.0, 
                                                      burn_type = "None")
                
                # calculate emissions and residual fuels for RX
                emissions_df <- calc_emissions(consumption_df, burn_type)
                
                # calculate emissions and residual fuels for wildfire
                emissions_df2 <- calc_emissions(consumption_df2, "None")
                
        }
        
        # RX piled only
        if(burn_type  == "Pile") {
                
                # simulate pile burn
                consumption_df <- ccon_activity_piled_only_fast(dt)
                
                # remove consumed fuel
                burn_again <- remove_rx_consumed(consumption_df, burn_type)
                
                # update fire weather
                burn_again[,":=" (Fm10  = Fm10_97,
                                  Fm1000 = Fm1000_97,
                                  Wind_corrected = Wind_corrected_97)]
                
                # simulate wildfire
                consumption_df2 <- ccon_activity_fast(burn_again, 
                                                      fm_type = "NFDRS_Th", 
                                                      days_since_rain = 50,
                                                      DRR = 2.0 / 3.0, 
                                                      burn_type = "None")
                
                # calculate emissions and residual fuels for RX
                emissions_df <- calc_emissions(consumption_df, burn_type)
                
                # calculate emissions and residual fuels for wildfire
                emissions_df2 <- calc_emissions(consumption_df2, "None")
                
        }
        
        if(burn_type == "None") {
                
                return(emissions_df)
                
        } else {
                
                return(list("first" = emissions_df, "second" = emissions_df2))
                
        }
}