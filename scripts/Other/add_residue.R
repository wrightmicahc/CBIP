################################################################################
# This script updates FCCS fuelbeds with treatment residues as part of the 
# California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# function for adding fuel
addfuel <- function(load, add, scattered, prop) {
        fuel <- load + ((add * scattered) * prop)
        return(fuel)
}

# function to allow dividing by 0
zero_div <- function(x, y) {
        return(ifelse(y == 0, 0, x / y))
}

add_residue <- function(dt, timestep) {
        
        # load the lookup table for scattered fuels
        lookup_scattered <- fread("data/SERC/lookup_tables/scattered_in_field.csv", 
                                  verbose = FALSE)
        
        # merge lookup and dt
        dt <-  merge(dt, 
                     lookup_scattered,
                     by = c("ID",
                            "Silvicultural_Treatment",
                            "Harvest_System",
                            "Harvest_Type",
                            "Burn_Type",
                            "Biomass_Collection"), 
                     all.x = TRUE,
                     all.y = FALSE,
                     sort = FALSE,
                     allow.cartesian = TRUE)
        
        # update fuelbed
        dt_plus <- dt[, .(x = x,
                          y = y,
                          fuelbed_number = fuelbed_number,
                          FCID2018 = FCID2018,
                          ID = ID,
                          Silvicultural_Treatment = Silvicultural_Treatment,
                          Harvest_Type = Harvest_Type,
                          Harvest_System = Harvest_System,
                          Burn_Type = Burn_Type,
                          Biomass_Collection = Biomass_Collection,
                          Slope = Slope,
                          Fm10 = Fm10,
                          Fm1000 = Fm1000,
                          Wind_corrected = Wind_corrected,
                          litter_ratio = litter_ratio,
                          litter_loading = addfuel(litter_loading,
                                                   decay_foliage(Foliage_tonsAcre, 
                                                                 Foliage_K,
                                                                 timestep,
                                                                 "foliage"),
                                                   Foliage,
                                                   1),
                          duff_upper_ratio = duff_upper_ratio,
                          duff_upper_depth = duff_upper_depth,
                          duff_lower_depth = duff_lower_depth,
                          duff_upper_loading = duff_upper_loading + decay_foliage(Foliage_tonsAcre, 
                                                                                  foliage_K, 
                                                                                  timestep,
                                                                                  "duff"), 
                          duff_lower_loading = duff_lower_loading,
                          lichen_depth = lichen_depth,
                          moss_depth = moss_depth,
                          one_hr_sound = addfuel(one_hr_sound,
                                                 decay_fun(Branch_tonsAcre,
                                                           FWD_K,
                                                           timestep),
                                                 Branch,
                                                 one_hr_sound_prop),
                          ten_hr_sound = addfuel(ten_hr_sound,
                                                 decay_fun(Branch_tonsAcre,
                                                           FWD_K,
                                                           timestep), 
                                                 Branch,
                                                 ten_hr_sound_prop),
                          hun_hr_sound = addfuel(hun_hr_sound,
                                                 decay_fun(Branch_tonsAcre,
                                                           FWD_K,
                                                           timestep),
                                                 Branch, 
                                                 hun_hr_sound_prop),
                          oneK_hr_sound = addfuel(oneK_hr_sound,
                                                  ((decay_fun(Stem_4t6_tonsAcre,
                                                              CWD_K,
                                                              timestep) * Stem_4t6) + 
                                                           (decay_fun(Stem_6t9_tonsAcre,
                                                                      CWD_K,
                                                                      timestep) * Stem_6t9)),
                                                  1,
                                                  oneK_hr_sound_prop),
                          tenK_hr_sound = addfuel(tenK_hr_sound,
                                                  decay_fun(Stem_ge9_tonsAcre, 
                                                            CWD_K,
                                                            timestep),
                                                  Stem_ge9, 
                                                  tenK_hr_sound_prop),
                          tnkp_hr_sound = addfuel(tnkp_hr_sound,
                                                  decay_fun(Stem_ge9_tonsAcre, 
                                                            CWD_K,
                                                            timestep),
                                                  Stem_ge9, 
                                                  tnkp_hr_sound_prop),
                          oneK_hr_rotten = oneK_hr_rotten,
                          tenK_hr_rotten = tenK_hr_rotten,
                          tnkp_hr_rotten = tnkp_hr_rotten,
                          pile_landing = pile_landing,
                          pile_field = pile_field,
                          one_hr_sound_prop = one_hr_sound_prop,
                          ten_hr_sound_prop = ten_hr_sound_prop,
                          hun_hr_sound_prop = hun_hr_sound_prop,
                          oneK_hr_sound_prop = oneK_hr_sound_prop,
                          tenK_hr_sound_prop = tenK_hr_sound_prop,
                          tnkp_hr_sound_prop = tnkp_hr_sound_prop)]
        
        # update upper duff depth with additional loading from foliage, if any
        dt_plus[, ':=' (duff_upper_depth = zero_div(duff_upper_loading,
                                                    duff_upper_ratio),
                        litter_depth = zero_div(litter_loading,
                                                litter_ratio))]
        
       
        return(dt_plus)
}
