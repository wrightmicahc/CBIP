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
                
                pdt[, pile_load := 0]
                
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
                                                     resid_pile))]
                
        }
        
        return(pdt)
}