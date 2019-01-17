################################################################################
# This script contains unit tests for con_calc_activity.R, comparing values in
# legacy code and new fast
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load necessary packages
library(data.table)
library(ggplot2)

# define ggplot theme
theme_set(theme_classic() +
                  theme(panel.grid.major = element_line(color = "grey90",
                                                        size = 0.2), 
                        strip.background = element_blank()))

# load the test data set
dt_test <- fread("data/Other/unit_test/test_fuel.csv")

# remove any fuelbeds with 0
dt_test <- dt_test[fuelbed_number != 0]

# get the first row
dt_trim <- dt_test[1, ]

# make a bunch of duplicates but change the burn type
burn_types <- c("None", "Broadcast", "Pile", "Jackpot")

dt_list <- lapply(burn_types, function(x) {
        dt_copy <- copy(dt_trim)
        dt_copy$Burn_Type <- x
        return(dt_copy)
        })

# source functions
source("scripts/Consume/con_calc_activity.R")
source("scripts/Other/burn_residue.R")

# define legacy function
burn_residue_legacy <- function(dt, burn_type) {
        
        if(burn_type  == "None") {
                
                # specify diameter reduction factor
                DRR  <- 2.0 / 3.0
                consumption_list <- lapply(seq(1:nrow(dt)),
                                           function(i){
                                                   z <- ccon_activity(fm1000 = dt[i, Fm1000],
                                                                      fm_type = "NFDRS_Th",
                                                                      wind = dt[i, Wind_corrected],
                                                                      slope = dt[i, Slope],
                                                                      fm10 = dt[i, Fm10],
                                                                      days_since_rain = 50,
                                                                      DRR = DRR,
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
        
        if(burn_type  == "Broadcast") {
                
                # specify diameter reduction factor
                DRR  <- 1 
                consumption_list <- lapply(seq(1:nrow(dt)),
                                           function(i){
                                                   z <- ccon_activity(fm1000 = dt[i, Fm1000],
                                                                      fm_type = "NFDRS_Th",
                                                                      wind = dt[i, Wind_corrected],
                                                                      slope = dt[i, Slope],
                                                                      fm10 = dt[i, Fm10],
                                                                      days_since_rain = 50,
                                                                      DRR = DRR,
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
                
                consumption_list <- lapply(seq(1:nrow(dt)),
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
        
        return(consumption_df)
}

# burn using legacy
legacy_out <- lapply(dt_list, function(x) burn_residue_legacy(x, x$Burn_Type))

# combine to a single dt
dt_legacy <- rbindlist(legacy_out)

# melt legacy
legacy_melt <- melt(dt_legacy[, .(e_spp,
                                  flaming,
                                  smoldering,
                                  residual,
                                  total,
                                  Burn_Type)],
                    measure.vars = c("flaming",
                                     "smoldering",
                                     "residual",
                                     "total"),
                    variable.factor = FALSE,
                    sort = FALSE)

# combine emissions species and combustion phase to single column
legacy_melt[, variable := paste(variable, e_spp, sep = "_")]

# burn using current
out <- lapply(dt_list, function(x) burn_residue(x, x$Burn_Type))

# combine to a single dt
dt_out <- rbindlist(out)

# melt out to match legacy
# first get id variables, including char columns
clmn_names <- names(dt_out)
id_names <- clmn_names[1:11]

out_melt <- melt(dt_out, 
                 id.vars = id_names,
                 variable.factor = FALSE,
                 sort = FALSE)

# combine the output
dt_comp <- merge(legacy_melt[, .(Burn_Type, variable, value)],
                 out_melt[, .(Burn_Type, variable, value)],
                 by = c("Burn_Type", "variable"),
                 suffixes = c("_legacy", "_current"))

# get the difference (absolute and proportional) in output
dt_comp[,  v_diff := abs(value_legacy - value_current)]
dt_comp[,  v_prop := v_diff/value_legacy]

# plot
ggplot(dt_comp, aes(variable, v_prop)) +
        geom_point() +
        geom_abline(slope = 0, intercept = 0) +
        scale_y_continuous(limits = c(0, 0.01)) +
        coord_flip() +
        facet_wrap(~ Burn_Type)

# any diff that are more than a gram?  
table(dt_comp$v_prop >= 1.1023e-6)
