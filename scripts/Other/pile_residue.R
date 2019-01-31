################################################################################
# This script adds columns to specify the pile load for biomass residue as part
# of the California Biopower Impact Project. 
# 
# Currently, it is assumed that foliage is piled along with the branches
#
# Author: Micah Wright, Humboldt State University
################################################################################

pile_residue <- function(dt, timestep) {
        # load the lookup table for landing piles
        lookup_landing <- fread("data/SERC/lookup_tables/piled_at_landing.csv", 
                                verbose = FALSE)
        
        # merge lookup and dt
        dt <-  merge(dt, 
                     lookup_landing,
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
        
        # calculate landing pile load
        dt[, pile_landing := ((Stem_ge9 * decay_fun(Stem_ge9_tonsAcre,
                                                    CWD_K * 0.7,
                                                    timestep)) + 
                                      (Stem_6t9 * decay_fun(Stem_6t9_tonsAcre,
                                                            CWD_K * 0.7,
                                                            timestep)) +
                                      (Stem_4t6 * decay_fun(Stem_4t6_tonsAcre,
                                                            CWD_K  * 0.7,
                                                            timestep)) +
                                      (Branch_tonsAcre * decay_fun(Branch, 
                                                                   FWD_K * 0.7,
                                                                   timestep)) +
                                      (Foliage_tonsAcre * decay_foliage(Foliage,
                                                                        Foliage_K * 0.7,
                                                                        timestep,
                                                                        "foliage")))]
        
        # remove excess columns
        dt[, c("Type",
               "Stem_ge9",
               "Stem_6t9",
               "Stem_4t6",
               "Branch",
               "Foliage") := NULL]
        
        # load the lookup table for landing piles
        lookup_field <- fread("data/SERC/lookup_tables/piled_in_field.csv", 
                              verbose = FALSE)
        
        # merge lookup and dt
        dt <-  merge(dt, 
                     lookup_field,
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
        
        # calculate field pile load
        dt[, pile_field := ((Stem_ge9 * decay_fun(Stem_ge9_tonsAcre,
                                                  CWD_K * 0.7,
                                                  timestep)) + 
                                    (Stem_6t9 * decay_fun(Stem_6t9_tonsAcre,
                                                          CWD_K * 0.7,
                                                          timestep)) +
                                    (Stem_4t6 * decay_fun(Stem_4t6_tonsAcre,
                                                          CWD_K  * 0.7,
                                                          timestep)) +
                                    (Branch_tonsAcre * decay_fun(Branch, 
                                                                 FWD_K * 0.7,
                                                                 timestep)) +
                                    (Foliage_tonsAcre * decay_foliage(Foliage,
                                                                      Foliage_K * 0.7,
                                                                      timestep,
                                                                      "foliage")))]
        
        # remove excess columns
        dt[, c("Type",
               "Stem_ge9",
               "Stem_6t9",
               "Stem_4t6",
               "Branch",
               "Foliage") := NULL]
        
        return(dt)
}
