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
                pdt[, ':=' (duff_upper_loading = duff_upper_loading - total_duff,
                            litter_loading = litter_loading - total_litter,
                            one_hr_sound = 0,
                            ten_hr_sound = 0,
                            hun_hr_sound = hun_hr_sound - total_100,
                            oneK_hr_sound = oneK_hr_sound - total_OneK_snd,
                            oneK_hr_rotten = oneK_hr_rotten - total_OneK_rot,
                            tenK_hr_sound = tenK_hr_sound - total_tenK_snd,
                            tenK_hr_rotten = tenK_hr_rotten - total_tenK_rot,
                            tnkp_hr_sound = tnkp_hr_sound - total_tnkp_snd,
                            tnkp_hr_rotten = tnkp_hr_rotten - total_tnkp_rot)]
                
        }
        
        # remove unecessary columns
        pdt[, c("total_duff", 
                "total_litter",
                "total_1",
                "total_10",
                "total_100",
                "total_OneK_snd",
                "total_OneK_rot",
                "total_tenK_snd", 
                "total_tenK_rot",
                "total_tnkp_snd", 
                "total_tnkp_rot",
                "flamg_pile", 
                "smoldg_pile",
                "resid_pile", 
                "char_100",
                "char_OneK_snd",
                "char_OneK_rot",
                "char_tenK_snd",
                "char_tenK_rot",
                "char_tnkp_snd",
                "char_tnkp_rot",
                "char_fwd_residue",
                "char_cwd_residue",
                "pile_char") := NULL]
        
        return(pdt)
}