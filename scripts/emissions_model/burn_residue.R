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

burn_residue <- function(dt, burn_type) {
        # wildfire
        if(burn_type  == "None") {
                
                # specify diameter reduction factor
                DRR  <- 2.0 / 3.0
                consumption_df <- ccon_activity_fast(dt, 
                                                     fm_type = "NFDRS_Th",
                                                     days_since_rain = 50,
                                                     DRR = DRR)
                
                emissions_df <- calc_emissions(consumption_df, burn_type)
                
        }
        # RX with scattered and piled fuels
        if(burn_type  == "Broadcast") {
                
                # specify diameter reduction factor
                DRR  <- 1 
                consumption_df <- ccon_activity_fast(dt, 
                                                     fm_type = "NFDRS_Th", 
                                                     days_since_rain = 50,
                                                     DRR = DRR)
                
                emissions_df <- calc_emissions(consumption_df, burn_type)
                
        }
        
        # RX piled only
        if(burn_type %in% c("Pile",
                            "Jackpot")) {
                
                consumption_df <- ccon_activity_piled_only_fast(dt, burn_type)
                
                emissions_df <- calc_emissions(consumption_df, burn_type)
                
        }
        
        return(emissions_df)
}