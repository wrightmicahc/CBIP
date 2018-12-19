################################################################################
# This script uses the consume activity equations to burn residue as part of the
# California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# source function that calculates consumption and emissions
source("scripts/Consume/con_calc_activity.R")

library(parallel)

burn_residue <- function(dt, burn_type) {
        
        if(burn_type %in% c("None",
                            "Broadcast")) {
                
                consumption_list <- mclapply(seq(1:nrow(dt)),
                                             mc.cores = detectCores() - 1,
                                             function(i){
                                                     z <- ccon_activity(fm1000 = dt[i, Fm1000],
                                                                        fm_type = "NFDRS_Th",
                                                                        wind = dt[i, Wind_corrected],
                                                                        slope = dt[i, Slope],
                                                                        fm10 = dt[i, Fm10],
                                                                        days_since_rain = 50,
                                                                        LD = dt[i,])
                                                     z$x <- dt[i, x]
                                                     z$y <- dt[i, y]
                                                     z$fuelbed_number <- dt[i, fuelbed_number]
                                                     z$FCID2018 <- dt[i, FCID2018]
                                                     z$ID <- dt[i, ID]
                                                     z$Silvicultural_Treatment <- dt[i, Silvicultural_Treatment]
                                                     z$Harvest_Type <- dt[i, Harvest_Type]
                                                     z$Harvest_System <- dt[i, Harvest_System]
                                                     z$Burn_Type <- dt[i, Burn_Type]
                                                     z$Biomass_Collection <- dt[i, Biomass_Collection]
                                                     return(as.data.table(z))
                                             })
                
        }
        
        if(burn_type %in% c("Pile",
                            "Jackpot")) {
                
                consumption_list <- mclapply(seq(1:nrow(dt)),
                                             mc.cores = detectCores(),
                                             function(i){
                                                     z <- ccon_activity_piled_only(LD = dt[i,])
                                                     z$x <- dt[i, x]
                                                     z$y <- dt[i, y]
                                                     z$fuelbed_number <- dt[i, fuelbed_number]
                                                     z$FCID2018 <- dt[i, FCID2018]
                                                     z$ID <- dt[i, ID]
                                                     z$Silvicultural_Treatment <- dt[i, Silvicultural_Treatment]
                                                     z$Harvest_Type <- dt[i, Harvest_Type]
                                                     z$Harvest_System <- dt[i, Harvest_System]
                                                     z$Burn_Type <- dt[i, Burn_Type]
                                                     z$Biomass_Collection <- dt[i, Biomass_Collection]
                                                     return(as.data.table(z))
                                             })
                
        }
        
        consumption_df <- rbindlist(consumption_list)
        
        consumption_df <- melt(consumption_df, 
                               id.vars = c("x",
                                           "y",
                                           "e_spp",
                                           "fuelbed_number",
                                           "FCID2018",
                                           "ID",
                                           "Silvicultural_Treatment",
                                           "Harvest_Type",
                                           "Harvest_System",
                                           "Burn_Type",
                                           "Biomass_Collection"),
                               measure.vars = c("flaming",
                                                "smoldering",
                                                "residual",
                                                "total"),
                               variable.name = "c_phase", 
                               value.name = "emissions",
                               variable.factor = FALSE)
        
        return(consumption_df)
}