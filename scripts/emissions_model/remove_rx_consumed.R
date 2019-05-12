################################################################################
# This script removes the consumed fuel following RX burns when the fuelbed is  
# scheduled to be consumed in a wildfire within a short period of time. It does 
# not consider decay.
#
# dt: output from con_calc_activity_fast
#
# Author: Micah Wright 
################################################################################


remove_rx_consumed <- function(dt, burn_type) {
        
        # copy 
        pdt <- copy(dt)
        
        if (burn_type == "Pile") {
                
                pdt[, ":=" (pile_load = 0,
                            pile_char_rx = pile_char)]
                
                pdt[, "pile_char" := NULL]
                
        } else {
                
                # caclulate remaining fuel for each size class
                # TODO: check to make sure depths are correct
                pdt[, ':=' (duff_upper_loading = duff_upper_loading - total_duff,
                            duff_upper_depth = duff_upper_loading * duff_upper_ratio,
                            litter_loading = litter_loading - total_litter,
                            litter_depth = litter_loading * litter_ratio,
                            one_hr_sound = 0,
                            ten_hr_sound = 0,
                            hun_hr_sound = hun_hr_sound - total_100,
                            oneK_hr_sound = oneK_hr_sound - total_OneK_snd,
                            oneK_hr_rotten = oneK_hr_rotten - total_OneK_rot,
                            tenK_hr_sound = tenK_hr_sound - total_tenK_snd,
                            tenK_hr_rotten = tenK_hr_rotten - total_tenK_rot,
                            tnkp_hr_sound = tnkp_hr_sound - total_tnkp_snd,
                            tnkp_hr_rotten = tnkp_hr_rotten - total_tnkp_rot,
                            pile_load = pile_load - (flamg_pile +
                                                     smoldg_pile +
                                                     resid_pile),
                            char_100_rx = char_100,
                            char_OneK_snd_rx = char_OneK_snd,
                            char_OneK_rot_rx = char_OneK_rot,
                            char_tenK_snd_rx = char_tenK_snd,
                            char_tenK_rot_rx = char_tenK_rot,
                            char_tnkp_snd_rx = char_tnkp_snd,
                            char_tnkp_rot_rx = char_tnkp_rot,
                            pile_char_rx = pile_char)]
                
                # remove old char columns
                pdt[, c("char_100",
                        "char_OneK_snd",
                        "char_OneK_rot",
                        "char_tenK_snd",
                        "char_tenK_rot",
                        "char_tnkp_snd",
                        "char_tnkp_rot",
                        "pile_char") := NULL]
                
        }
        
        return(pdt)
}