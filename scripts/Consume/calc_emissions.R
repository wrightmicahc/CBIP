################################################################################
# This script calculates the emissoms for each catagory consumed.
#
# Author: Micah Wright 
################################################################################

# general emissions factors data, taken directly from fepsef.py in the bluesky
# emissions framework
ef_db <- list("flamg" = c("CH4" =  0.003819999999999997,
                          "CO" = 0.07179999999999997,
                          "CO2" = 1.6497,
                          "NH3" = 0.0012063999999999998,
                          "NOx" = 0.002420000000000001,
                          "PM10" = 0.008590399999999998,
                          "PM2.5" = 0.007280000000000002,
                          "SO2" = 0.00098,
                          "VOC" = 0.017341999999999996),
              
              "smoldg"= c("CH4" = 0.009868000000000002,
                          "CO" = 0.21011999999999997,
                          "CO2" = 1.39308,
                          "NH3" = 0.00341056,
                          "NOx" = 0.000908,
                          "PM10" = 0.01962576,
                          "PM2.5" = 0.016632,
                          "SO2" = 0.00098,
                          "VOC" = 0.04902680000000001),
              
              "resid"= c("CH4" = 0.009868000000000002,
                         "CO" = 0.21011999999999997,
                         "CO2" = 1.39308,
                         "NH3" = 0.00341056,
                         "NOx" = 0.000908,
                         "PM10" = 0.01962576,
                         "PM2.5" = 0.016632,
                         "SO2" = 0.00098,
                         "VOC" = 0.04902680000000001))

# emissions factors data for piles, same as above but with piles ef from Consume
# source where available
ef_db_pile <- list("pm" = list("clean" = c("PM10" = 15.5 / 2000,
                                           "PM2.5" = 13.5 / 2000),
                               
                               "vdirty" = c("PM10" = 28 / 2000,
                                            "PM2.5" = 23.6 / 2000)),
                   
                   "flamg" = c("CH4" =  3.28 / 2000,
                               "CO" = 52.66 / 2000,
                               "CO2" = 3429.24 / 2000,
                               "NH3" = 0.0012063999999999998,
                               "NOx" = 0.002420000000000001,
                               "SO2" = 0.00098,
                               "VOC" = 0.017341999999999996),
                   
                   "smoldg"= c("CH4" = 11.03 / 2000,
                               "CO" = 130.37 / 2000,
                               "CO2" = 3089.88 / 2000,
                               "NH3" = 0.00341056,
                               "NOx" = 0.000908,
                               "SO2" = 0.00098,
                               "VOC" = 0.04902680000000001),
                   
                   "resid"= c("CH4" = 11.03 / 2000,
                              "CO" = 130.37 / 2000,
                              "CO2" = 3089.88 / 2000,
                              "NH3" = 0.00341056,
                              "NOx" = 0.000908,
                              "SO2" = 0.00098,
                              "VOC" = 0.04902680000000001))

calc_emissions <- function(dt, burn_type) {
        
        ########################################################################
        # calculate total emissions for each emissions species by combustion
        # phase. This includes the orginal fuelbed.
        ########################################################################
        
        # Start with emissions species
        e_spp <- c("CH4", "CO", "CO2", "NH3", "NOx", "PM10", "PM2.5", "SO2", "VOC")
        # now all combos of combustion phase
        cnames <- c("total_flamg", "total_smoldg", "total_resid")
        
        # loop through each combination and multiply the emissions factor by the 
        # consumed mass
        for (col in paste(cnames, rep(e_spp, each = length(cnames)), sep = "_")) {
                dt[ , (col) := dt[[gsub("(.*)_.*","\\1", col)]] * ef_db[[gsub("^([^_]+_){1}(.+)_.*$","\\2", col)]][[sub(".*\\_", "", col)]]]
        }
        
        ########################################################################
        # calculate emissions from piled fuels for each emissions species by 
        # combustion phase, except PM. All piled fuels are residue since we 
        # ignore original piles in the fuelbed
        ########################################################################
        
        # emissions species
        e_spp <- c("CH4", "CO", "CO2", "NH3", "NOx", "SO2", "VOC")
        # pile combustion phase 
        cnames <- paste(c("flamg", "smoldg", "resid"), "pile", sep = "_")
        
        # loop though each combo and multiply the emissions factor by the 
        # consumed mass
        for (col in paste(cnames, rep(e_spp, each = length(cnames)), sep = "_")) {
                dt[ , (col) := dt[[gsub("(.*)_.*","\\1", col)]] * ef_db_pile[[sub("_.*", "", col)]][[sub(".*\\_", "", col)]]]
        }
        
        # now pms. this requires a third component: pile cleanliness
        e_spp <- c("PM10", "PM2.5")
        cnames <- paste(rep(cnames, each = 2), c("clean", "vdirty"), sep = "_")
        
        # loop though each combo and multiply the emissions factor by the 
        # consumed mass
        for (col in paste(cnames, rep(e_spp, each = length(cnames)), sep = "_")) {
                dt[ , (col) := dt[[gsub("^([^_]*_[^_]*)_.*$", "\\1", col)]] * ef_db_pile[["pm"]][[gsub("^([^_]+_){2}(.+)_.*$","\\2", col)]][[sub(".*\\_", "", col)]]]
        }
        
        ########################################################################
        # calculate emissions for residue by c phase, emissions species, and 
        # size class. Size class is one of duff, foliage, fwd, and cwd. this 
        # does not include the orginal fuelbed.
        ########################################################################
        
        # emissions species
        e_spp <- c("CH4", "CO", "CO2", "NH3", "NOx", "PM10", "PM2.5", "SO2", "VOC")
        # now all combos of size class and c phase
        size <- c("duff_residue", "foliage_residue", "fwd_residue", "cwd_residue")
        cnames <- paste(rep(c("flamg", "smoldg", "resid"), each = length(size)),
                        size, sep = "_")
        
        # loop though each combo and multiply the emissions factor by the 
        # consumed mass
        for (col in paste(cnames, rep(e_spp, each = length(cnames)), sep = "_")) {
                dt[ , (col) := dt[[gsub("(.*)_.*","\\1", col)]] * ef_db[[sub("_.*", "", col)]][[sub(".*\\_", "", col)]]]
        }
        
        ########################################################################
        # calculate total emissions by species for all consumed mass, including
        # any emissions from the orginal fuelbed.
        ########################################################################
        
        # get total emissions including original fuelbed
        e_spp <- c("CH4", "CO", "CO2", "NH3", "NOx", "PM10", "PM2.5", "SO2", "VOC")
        
        # loop though each combo and get the emissions for all combustion including original fuelbed
        for (col in e_spp) {
                dt[ , paste0("total_", col) := rowSums(.SD), .SDcols = paste("total", c("flamg", "smoldg", "resid"), col, sep = "_")]
        }
        ########################################################################
        # calculate total char
        ########################################################################
        dt[, total_char := rowSums(.SD), .SDcols = c("char_100",
                                                     "char_OneK_snd",
                                                     "char_OneK_rot",
                                                     "char_tenK_snd",
                                                     "char_tenK_rot",
                                                     "char_tnkp_snd",
                                                     "char_tnkp_rot")]
        ########################################################################
        # calculate total emissions by emissions species and size for residue 
        # only. Does not include any emissions from the orginal fuelbed.
        ########################################################################
        
        # size class, emissions spp don't change
        size <- c("duff_residue", "foliage_residue", "fwd_residue", "cwd_residue")
        cnames <- paste(size, rep(e_spp, each = length(size)), sep = "_")
        # loop though each combo and get the emissions for all combustion of residue
        for (col in cnames) {
                dt[ , paste0("total_", col) := rowSums(.SD), .SDcols = paste(c("flamg", "smoldg", "resid"), col, sep = "_")]
        }
        
        ########################################################################
        # calculate total emissions by emissions species and piles. Again, does 
        # not include any emissions from the orginal fuelbed.
        ########################################################################
        e_spp <- c("PM10", "PM2.5")
        cnames <- paste(c("clean", "vdirty"), rep(e_spp, each = 2), sep = "_")
        
        cnames <- paste("pile", c(cnames, c("CH4", "CO", "CO2", "NH3", "NOx", "SO2", "VOC")), sep = "_")
        
        # loop though each combo and get the emissions
        for (col in cnames) {
                dt[ ,paste0("total_", (col)) := rowSums(.SD), .SDcols = paste(c("flamg", "smoldg", "resid"), (col), sep = "_")]
        }
        
        # define output data 
        out_dt <- dt[,list(x, 
                           y,
                           fuelbed_number, 
                           FCID2018, 
                           ID,
                           Silvicultural_Treatment, 
                           Harvest_Type,
                           Harvest_System,
                           Burn_Type,
                           Biomass_Collection,
                           Year,
                           Slope,
                           Fm10,
                           Fm1000,
                           Wind_corrected,
                           residue_burned,
                           duff_upper_loading = (duff_upper_loading - total_duff) * duff_upper_load_pr,
                           litter_loading = (litter_loading - total_litter) * litter_loading_pr, 
                           one_hr_sound = (one_hr_sound - total_1) * one_hr_sound_pr, 
                           ten_hr_sound = (ten_hr_sound - total_10) * ten_hr_sound_pr, 
                           hun_hr_sound = (hun_hr_sound - total_100) * hun_hr_sound_pr,
                           oneK_hr_sound = ((oneK_hr_sound - total_OneK_snd) * oneK_hr_sound_pr) + ((pile_field + pile_landing) - (flamg_pile + smoldg_pile + resid_pile)),
                           oneK_hr_rotten = (oneK_hr_rotten - total_OneK_rot) * oneK_hr_rotten_pr,
                           tenK_hr_sound = (tenK_hr_sound - total_tenK_snd) * tenK_hr_sound_pr, 
                           tenK_hr_rotten = (tenK_hr_rotten - total_tenK_rot) * tenK_hr_rotten_pr,
                           tnkp_hr_sound = (tnkp_hr_sound - total_tnkp_snd) * tnkp_hr_sound_pr,
                           tnkp_hr_rotten = (tnkp_hr_rotten - total_tnkp_rot) * tnkp_hr_rotten_pr,
                           pile_field = ifelse(burn_type == "Pile", pile_field, 0),
                           pile_landing = 0,
                           duff_upper_load_pr,
                           litter_loading_pr,
                           one_hr_sound_pr,
                           ten_hr_sound_pr,
                           hun_hr_sound_pr,
                           oneK_hr_sound_pr,
                           tenK_hr_sound_pr,
                           tnkp_hr_sound_pr,
                           oneK_hr_rotten_pr,
                           tenK_hr_rotten_pr,
                           tnkp_hr_rotten_pr,
                           total_char,
                           total_CH4, 
                           total_CO, 
                           total_CO2,
                           total_NH3,
                           total_NOx, 
                           total_PM10, 
                           total_PM2.5,
                           total_SO2, 
                           total_VOC,
                           total_pile_clean_PM10, 
                           total_pile_vdirty_PM10,
                           total_pile_clean_PM2.5,
                           total_pile_vdirty_PM2.5, 
                           total_pile_CH4,
                           total_pile_CO,
                           total_pile_CO2,              
                           total_pile_NH3,
                           total_pile_NOx,
                           total_pile_SO2,
                           total_pile_VOC,
                           pile_char,
                           char_fwd_residue,
                           char_cwd_residue,
                           total_duff_residue_CH4,      
                           total_foliage_residue_CH4,
                           total_fwd_residue_CH4,
                           total_cwd_residue_CH4,    
                           total_duff_residue_CO,
                           total_foliage_residue_CO,
                           total_fwd_residue_CO,
                           total_cwd_residue_CO,
                           total_duff_residue_CO2,
                           total_foliage_residue_CO2,
                           total_fwd_residue_CO2,
                           total_cwd_residue_CO2,
                           total_duff_residue_NH3,
                           total_foliage_residue_NH3,
                           total_fwd_residue_NH3,
                           total_cwd_residue_NH3,
                           total_duff_residue_NOx,
                           total_foliage_residue_NOx,
                           total_fwd_residue_NOx,
                           total_cwd_residue_NOx,
                           total_duff_residue_PM10,
                           total_foliage_residue_PM10,
                           total_fwd_residue_PM10,
                           total_cwd_residue_PM10,
                           total_duff_residue_PM2.5,
                           total_foliage_residue_PM2.5,
                           total_fwd_residue_PM2.5,
                           total_cwd_residue_PM2.5,
                           total_duff_residue_SO2,
                           total_foliage_residue_SO2,
                           total_fwd_residue_SO2,
                           total_cwd_residue_SO2,
                           total_duff_residue_VOC,
                           total_foliage_residue_VOC,
                           total_fwd_residue_VOC,
                           total_cwd_residue_VOC)]
        
        return(out_dt)
}