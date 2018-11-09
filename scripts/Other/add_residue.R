################################################################################
# This script updates FCCS fuelbeds with treatment residues as part of the 
# California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# function for adding fuel
addfuel <- function(load, add, pile, prop) {
        fuel <- load + ((add * (1 - pile)) * prop)
        return(fuel)
}

# function to allow dividing by 0
zero_div <- function(x, y) {
        return(ifelse(y == 0, 0, x / y))
}

add_residue <- function(dt){

        # update fuelbed
        dt_plus <- dt[, .(x = x,
                          y = y,
                          fuelbed_number = fuelbed_number,
                          FCID2018 = FCID2018,
                          Treatment = Treatment,
                          Slope = Slope,
                          Fm10 = Fm10,
                          Fm1000 = Fm1000,
                          Wind_corrected = Wind_corrected,
                          litter_loading = addfuel(litter_loading,
                                                   Foliage_tonsAcre, 
                                                   0,
                                                   1),
                          duff_upper_depth = duff_upper_depth,
                          duff_lower_depth = duff_lower_depth,
                          lichen_depth = lichen_depth,
                          moss_depth = moss_depth,
                          one_hr_sound = addfuel(one_hr_sound,
                                                 Branch_tonsAcre, 
                                                 piled_prop,
                                                 one_hr_sound_prop),
                          ten_hr_sound = addfuel(ten_hr_sound,
                                                 Branch_tonsAcre, 
                                                 piled_prop,
                                                 ten_hr_sound_prop),
                          hun_hr_sound = addfuel(hun_hr_sound,
                                                 Branch_tonsAcre,
                                                 piled_prop, 
                                                 hun_hr_sound_prop),
                          oneK_hr_sound = addfuel(oneK_hr_sound,
                                                  Break_4t9_tonsAcre,
                                                  piled_prop,
                                                  oneK_hr_sound_prop),
                          tenK_hr_sound = addfuel(tenK_hr_sound,
                                                  Break_ge9_tonsAcre, 
                                                  piled_prop, 
                                                  tenK_hr_sound_prop),
                          tnkp_hr_sound = addfuel(tnkp_hr_sound,
                                                  Break_ge9_tonsAcre,
                                                  piled_prop, 
                                                  tnkp_hr_sound_prop),
                          oneK_hr_rotten = oneK_hr_rotten,
                          tenK_hr_rotten = tenK_hr_rotten,
                          tnkp_hr_rotten = tnkp_hr_rotten)]
        
        dt_plus$pile_load <- rowSums(dt[, c("Break_4t9_tonsAcre",
                                            "Break_ge9_tonsAcre",
                                            "Pulp_4t6_tonsAcre",
                                            "Pulp_6t9_tonsAcre",
                                            "Branch_tonsAcre")]) * dt$piled_prop
        
        dt_plus$litter_depth <- zero_div(dt_plus$litter_loading,
                                         dt$litter_ratio)
        return(dt_plus)
}
