################################################################################
# This script adds the residual fuel from RX burns back onto a recovered fuelbed
# at each timestep. Includes decay. This is part of the CA Biopower Impact
# Project.
#
# dt_rx: rx burn output data table
# dt_fuel: fuelbed without additional residues added
# timestep: numeric
#
# Author: Micah Wright, Humboldt State University
################################################################################

add_rx_residue <- function(dt_rx, dt_fuel, timestep) {
        
        dt <- merge(dt_fuel,
                    dt_rx[, .(x, 
                              y,
                              hun_hr_sound_b = hun_hr_sound,
                              oneK_hr_sound_b = oneK_hr_sound,
                              oneK_hr_rotten_b = oneK_hr_rotten,
                              tenK_hr_sound_b = tenK_hr_sound,
                              tenK_hr_rotten_b = tenK_hr_rotten,
                              tnkp_hr_sound_b = tnkp_hr_sound,
                              tnkp_hr_rotten_b = tnkp_hr_rotten,
                              litter_loading_b = litter_loading,
                              duff_upper_loading_b = duff_upper_loading)],
                    by = c("x", "y"))
        
        dt[, ':=' (litter_toadd = decay_foliage(litter_loading_b, 
                                                Foliage_K,
                                                timestep,
                                                "foliage"),
                   duff_toadd = decay_foliage(litter_loading_b, 
                                              Foliage_K, 
                                              timestep,
                                              "duff") + 
                           to_duff(hun_hr_sound_b,
                                   FWD_K,
                                   timestep) +
                           to_duff(oneK_hr_sound_b,
                                   CWD_K,
                                   timestep) +
                           to_duff(oneK_hr_rotten_b,
                                   CWD_K,
                                   timestep) +
                           to_duff(tenK_hr_sound_b,
                                   CWD_K,
                                   timestep) +
                           to_duff(tenK_hr_rotten_b,
                                   CWD_K,
                                   timestep) +
                           to_duff(tnkp_hr_sound_b,
                                   CWD_K,
                                   timestep) +
                           to_duff(tnkp_hr_rotten_b,
                                   CWD_K,
                                   timestep) +
                           duff_upper_loading_b,
                   hun_hr_toadd = decay_fun(hun_hr_sound_b,
                                            FWD_K,
                                            timestep),
                   oneK_hr_sound_toadd = decay_woody(oneK_hr_sound_b,
                                                     CWD_K,
                                                     timestep,
                                                     "sound"),
                   oneK_hr_rotten_toadd = (decay_woody(oneK_hr_sound_b,
                                                      CWD_K,
                                                      timestep,
                                                      "rotten") +
                                                   decay_fun(oneK_hr_rotten_b,
                                                             CWD_K,
                                                             timestep)),
                   tenK_hr_sound_toadd = decay_woody(tenK_hr_sound_b, 
                                                     CWD_K,
                                                     timestep,
                                                     "sound"),
                   tenK_hr_rotten_toadd = (decay_woody(tenK_hr_sound_b, 
                                                      CWD_K,
                                                      timestep,
                                                      "rotten") + 
                                                   decay_fun(tenK_hr_rotten_b,
                                                             CWD_K,
                                                             timestep)),
                   tnkp_hr_sound_toadd = decay_woody(tnkp_hr_sound_b, 
                                                     CWD_K,
                                                     timestep,
                                                     "sound"),
                   tnkp_hr_rotten_toadd = (decay_woody(tnkp_hr_sound_b, 
                                                       CWD_K,
                                                       timestep,
                                                       "rotten") +
                                                   decay_fun(tnkp_hr_rotten_b,
                                                             CWD_K,
                                                             timestep)))]
        dt[, ':=' (residue_burned = (litter_toadd + 
                                             duff_toadd + 
                                             hun_hr_toadd + 
                                             oneK_hr_sound_toadd + 
                                             oneK_hr_rotten_toadd + 
                                             tenK_hr_sound_toadd +
                                             tenK_hr_rotten_toadd +
                                             tnkp_hr_sound_toadd + 
                                             tnkp_hr_rotten_toadd))]
        
        dt[, ':=' (duff_upper_load_pr = propfuel(duff_upper_loading,
                                                 duff_toadd,
                                                 1),
                   litter_loading_pr = propfuel(litter_loading,
                                                litter_toadd,
                                                1),
                   hun_hr_sound_pr = propfuel(hun_hr_sound,
                                              hun_hr_toadd,
                                              1),
                   oneK_hr_sound_pr = propfuel(oneK_hr_sound,
                                               oneK_hr_sound_toadd,
                                               1),
                   oneK_hr_rotten_pr = propfuel(oneK_hr_rotten,
                                                oneK_hr_rotten_toadd,
                                                1),
                   tenK_hr_sound_pr = propfuel(tenK_hr_sound,
                                               tenK_hr_sound_toadd,
                                               1),
                   tenK_hr_rotten_pr = propfuel(tenK_hr_rotten,
                                                tenK_hr_rotten_toadd,
                                                1),
                   tnkp_hr_sound_pr = propfuel(tnkp_hr_sound,
                                               tnkp_hr_sound_toadd,
                                               1),
                   tnkp_hr_rotten_pr = propfuel(tnkp_hr_rotten,
                                                tnkp_hr_rotten_toadd,
                                                1),
                   Year = timestep)]
        
        dt[, ':=' (hun_hr_sound = hun_hr_sound + hun_hr_toadd,
                   oneK_hr_sound = oneK_hr_sound + oneK_hr_sound_toadd,
                   oneK_hr_rotten = oneK_hr_rotten + oneK_hr_rotten_toadd,
                   tenK_hr_sound = tenK_hr_sound + tenK_hr_sound_toadd,
                   tenK_hr_rotten = tenK_hr_rotten + tenK_hr_rotten_toadd,
                   tnkp_hr_sound = tnkp_hr_sound + tnkp_hr_sound_toadd,
                   tnkp_hr_rotten = tnkp_hr_rotten + tnkp_hr_rotten_toadd,
                   duff_upper_loading = duff_upper_loading + duff_toadd,
                   litter_loading = litter_loading + litter_toadd,
                   pile_field = 0,
                   pile_landing = 0)]
        
        
        
        dt[, ':='  (duff_upper_depth = zero_div(duff_upper_loading,
                                                duff_upper_ratio),
                    litter_depth = zero_div(litter_loading,
                                            litter_ratio))]
        
        dt[, c("hun_hr_toadd",
               "oneK_hr_sound_toadd", 
               "oneK_hr_rotten_toadd", 
               "tenK_hr_sound_toadd",
               "tenK_hr_rotten_toadd",
               "tnkp_hr_sound_toadd", 
               "tnkp_hr_rotten_toadd", 
               "duff_toadd",
               "litter_toadd",
               "hun_hr_sound_b",
               "oneK_hr_sound_b",
               "oneK_hr_rotten_b",
               "tenK_hr_sound_b", 
               "tenK_hr_rotten_b", 
               "tnkp_hr_sound_b",
               "tnkp_hr_rotten_b",
               "litter_loading_b") := NULL]
        
        return(dt)
}
