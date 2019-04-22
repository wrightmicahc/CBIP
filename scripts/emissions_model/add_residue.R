################################################################################
# This script updates scattered fuels in FCCS fuelbeds with treatment residues
# as part of the California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################
# function to allow dividing by 0
zero_div <- function(x, y) {
        return(ifelse(y == 0, 0, x / y))
}

# function for adding fuel
addfuel <- function(load, add, prop) {
        fuel <- load + (add * prop)
        return(fuel)
}

# function for determining proportion of original that was added
propfuel <- function(load, add, prop) {
        pr <- zero_div(add * prop, 
                       (add * prop) + load)
                       
        return(pr)
}

# function that adds residue to fuelbed
# dt: input data.table
# timestep: years since treatment
add_residue <- function(dt, timestep) {
        
        # load the lookup table for scattered fuels
        lookup_scattered <- fread("data/SERC/lookup_tables/fake/scattered.csv", 
                                  verbose = FALSE)
        
        # add year column
        dt[, Year := timestep]
        
        # merge lookup and dt
        dt <-  merge(dt, 
                     lookup_scattered,
                     by = c("ID",
                            "Slope_Class",
                            "Silvicultural_Treatment",
                            "Fraction_Piled",
                            "Fraction_Scattered",
                            "Burn_Type",
                            "Biomass_Collection",
                            "Pulp_Market"), 
                     all.x = TRUE,
                     all.y = FALSE,
                     sort = TRUE,
                     allow.cartesian = FALSE)
        
        # calculate coarse load
        dt[, CWD := (Stem_ge9_tonsAcre * Stem_ge9) + (Stem_6t9_tonsAcre * Stem_6t9) + (Stem_4t6_tonsAcre * Stem_4t6)]
        
        # calculate amount to add by size class, account for decay and proportion scattered
        dt[, ':=' (litter_toadd = decay_foliage(Foliage_tonsAcre * Foliage, 
                                                        Foliage_K,
                                                        timestep,
                                                        "foliage"),
                   duff_toadd = decay_foliage(Foliage_tonsAcre * Foliage, 
                                                    Foliage_K, 
                                                    timestep,
                                                    "duff") + 
                           to_duff((Branch_tonsAcre * Branch),
                                        FWD_K,
                                        timestep) +
                           to_duff(CWD,
                                        CWD_K,
                                        timestep),
                   branch_toadd = decay_fun(Branch_tonsAcre * Branch,
                                            FWD_K,
                                            timestep),
                   Stem_4t9_toadd_sound = decay_woody(Stem_4t6_tonsAcre * Stem_4t6,
                                                      CWD_K,
                                                      timestep, 
                                                      "sound") + 
                           decay_woody(Stem_6t9_tonsAcre * Stem_6t9,
                                       CWD_K,
                                       timestep, 
                                       "sound"),
                   Stem_4t9_toadd_rotten = decay_woody(Stem_4t6_tonsAcre * Stem_4t6,
                                                       CWD_K,
                                                       timestep, 
                                                       "rotten") + 
                           decay_woody(Stem_6t9_tonsAcre * Stem_6t9,
                                       CWD_K,
                                       timestep, 
                                       "rotten"),
                   Stem_ge9_toadd_sound = decay_woody(Stem_ge9_tonsAcre * Stem_ge9, 
                                                      CWD_K,
                                                      timestep,
                                                      "sound"),
                   Stem_ge9_toadd_rotten = decay_woody(Stem_ge9_tonsAcre * Stem_ge9, 
                                                       CWD_K,
                                                       timestep,
                                                       "rotten"))]
        
        # update fuelbed
        dt[, ':=' (litter_loading = addfuel(litter_loading,
                                            litter_toadd,
                                            1),
                   duff_upper_loading = addfuel(duff_upper_loading,
                                                duff_toadd,
                                                1),
                   one_hr_sound = addfuel(one_hr_sound,
                                          branch_toadd,
                                          one_hr_sound_prop),
                   ten_hr_sound = addfuel(ten_hr_sound,
                                          branch_toadd,
                                          ten_hr_sound_prop),
                   hun_hr_sound = addfuel(hun_hr_sound,
                                          branch_toadd,
                                          hun_hr_sound_prop),
                   oneK_hr_sound = addfuel(oneK_hr_sound,
                                           Stem_4t9_toadd_sound,
                                           oneK_hr_sound_prop),
                   tenK_hr_sound = addfuel(tenK_hr_sound,
                                           Stem_ge9_toadd_sound,
                                           tenK_hr_sound_prop),
                   tnkp_hr_sound = addfuel(tnkp_hr_sound,
                                           Stem_ge9_toadd_sound,
                                           tnkp_hr_sound_prop),
                   oneK_hr_rotten = addfuel(oneK_hr_rotten,
                                            Stem_4t9_toadd_rotten,
                                            oneK_hr_sound_prop),
                   tenK_hr_rotten = addfuel(tenK_hr_rotten,
                                            Stem_ge9_toadd_rotten,
                                            tenK_hr_sound_prop),
                   tnkp_hr_rotten = addfuel(tnkp_hr_rotten,
                                            Stem_ge9_toadd_rotten,
                                            tnkp_hr_sound_prop),
                   duff_upper_load_pr = zero_div(duff_toadd,
                                                 (duff_upper_loading + duff_toadd)),
                   litter_loading_pr = zero_div(litter_toadd,
                                                (litter_loading + litter_toadd)),
                   one_hr_sound_pr = propfuel(one_hr_sound,
                                              branch_toadd,
                                              one_hr_sound_prop),
                   ten_hr_sound_pr = propfuel(ten_hr_sound,
                                              branch_toadd,
                                              ten_hr_sound_prop),
                   hun_hr_sound_pr = propfuel(hun_hr_sound,
                                              branch_toadd,
                                              hun_hr_sound_prop),
                   oneK_hr_sound_pr = propfuel(oneK_hr_sound,
                                               Stem_4t9_toadd_sound,
                                               oneK_hr_sound_prop),
                   tenK_hr_sound_pr = propfuel(tenK_hr_sound,
                                               Stem_ge9_toadd_sound,
                                               tenK_hr_sound_prop),
                   tnkp_hr_sound_pr = propfuel(tnkp_hr_sound,
                                               Stem_ge9_toadd_sound,
                                               tnkp_hr_sound_prop),
                   oneK_hr_rotten_pr = propfuel(oneK_hr_rotten,
                                                Stem_4t9_toadd_rotten,
                                                oneK_hr_sound_prop),
                   tenK_hr_rotten_pr = propfuel(tenK_hr_rotten,
                                                Stem_ge9_toadd_rotten,
                                                tenK_hr_sound_prop),
                   tnkp_hr_rotten_pr = propfuel(tnkp_hr_rotten,
                                                Stem_ge9_toadd_rotten,
                                                tnkp_hr_sound_prop))]
        
        # update upper duff depth with additional loading from foliage, if any
        dt[, ':=' (duff_upper_depth = zero_div(duff_upper_loading,
                                               duff_upper_ratio),
                   litter_depth = zero_div(litter_loading,
                                           litter_ratio))]
        
        # remove excess columns
        dt[, c("Stem_ge9", 
               "Stem_6t9",
               "Stem_4t6",
               "Branch",
               "Foliage",
               "CWD",
               "TPI",
               "CWD_K",
               "FWD_K",
               "Foliage_K",
               "one_hr_sound_prop",
               "ten_hr_sound_prop",
               "hun_hr_sound_prop",
               "oneK_hr_sound_prop",
               "tenK_hr_sound_prop",
               "tnkp_hr_sound_prop",
               "TPA",
               "Stem_6t9_tonsAcre",
               "Stem_4t6_tonsAcre",
               "Stem_ge9_tonsAcre",
               "Branch_tonsAcre",
               "Foliage_tonsAcre",
               "litter_toadd",
               "duff_toadd",
               "branch_toadd",
               "Stem_4t9_toadd_sound",
               "Stem_4t9_toadd_rotten",
               "Stem_ge9_toadd_sound",
               "Stem_ge9_toadd_rotten") := NULL]
        
        return(dt)
}
