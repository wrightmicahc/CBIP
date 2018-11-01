################################################################################
# This script uses the consume activity equations to burn residue as part of the
# California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

burn_residue <- function(dt) {
        
        library(parallel)
        
        browser()
        
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
                                             z$Treatment <- dt[i, Treatment]
                                             z$biomass_removed <- dt[i, biomass_removed]
                                             return(as.data.table(z))
                                     })
        
        consumption_df <- rbindlist(consumption_list)
        
        consumption_df <- melt(consumption_df, 
                               id.vars = c("x",
                                           "y",
                                           "e_spp",
                                           "fuelbed_number",
                                           "FCID2018",
                                           "Treatment",
                                           "biomass_removed"),
                               measure.vars = c("flaming",
                                                "smoldering",
                                                "residual",
                                                "total"),
                               variable.name = "c_phase", 
                               value.name = "emissions",
                               variable.factor = FALSE)
        
        return(consumption_df)
}