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

add_residue <- function(dt) {
        
        # load the lookup table for landing piles
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
                          litter_loading = addfuel(litter_loading,
                                                   Foliage_tonsAcre, 
                                                   Foliage,
                                                   1),
                          duff_upper_depth = duff_upper_depth,
                          duff_lower_depth = duff_lower_depth,
                          duff_upper_loading = duff_upper_loading, 
                          lichen_depth = lichen_depth,
                          moss_depth = moss_depth,
                          one_hr_sound = addfuel(one_hr_sound,
                                                 Branch_tonsAcre, 
                                                 Branch,
                                                 one_hr_sound_prop),
                          ten_hr_sound = addfuel(ten_hr_sound,
                                                 Branch_tonsAcre, 
                                                 Branch,
                                                 ten_hr_sound_prop),
                          hun_hr_sound = addfuel(hun_hr_sound,
                                                 Branch_tonsAcre,
                                                 Branch, 
                                                 hun_hr_sound_prop),
                          oneK_hr_sound = addfuel(oneK_hr_sound,
                                                  ((Stem_4t6_tonsAcre * Stem_4t6) + (Stem_6t9_tonsAcre + Stem_6t9)),
                                                  1,
                                                  oneK_hr_sound_prop),
                          tenK_hr_sound = addfuel(tenK_hr_sound,
                                                  Stem_ge9_tonsAcre, 
                                                  Stem_ge9, 
                                                  tenK_hr_sound_prop),
                          tnkp_hr_sound = addfuel(tnkp_hr_sound,
                                                  Stem_ge9_tonsAcre, 
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
        
        dt_plus$litter_depth <- zero_div(dt_plus$litter_loading,
                                         dt$litter_ratio)
        return(dt_plus)
}
