################################################################################
# This script adds columns to specify the pile load for biomass residue as part
# of the California Biopower Impact Project. Currently, it is assumed that 
# foliage is piled along with the branches.
#
# dt: input data.table
# timestep: years from treatment
#
# Author: Micah Wright, Humboldt State University
################################################################################

pile_residue <- function(dt, timestep) {
        
        # specify the coefficient for pile K
        pK_coeff <- 0.7516606

        # load the lookup table for piled fuels
        lookup_pile <- fread("data/SERC/lookup_tables/fake/piled.csv", 
                                verbose = FALSE)
        
        # merge lookup and dt
        dt <-  merge(dt, 
                     lookup_pile,
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
        
        # calculate landing pile load
        dt[, pile_load := decay_fun(CWD,
                                    CWD_K * pK_coeff,
                                    timestep) + 
                   to_duff(CWD,
                           CWD_K * pK_coeff,
                           timestep) +
                   decay_fun(Branch_tonsAcre * Branch,
                             FWD_K * pK_coeff,
                             timestep) +
                   to_duff(Branch_tonsAcre * Branch,
                           FWD_K * pK_coeff,
                           timestep) +
                   decay_foliage(Foliage_tonsAcre * Foliage, 
                                 Foliage_K * pK_coeff,
                                 timestep,
                                 "foliage") +
                   decay_foliage(Foliage_tonsAcre * Foliage, 
                                 Foliage_K * pK_coeff, 
                                 timestep,
                                 "duff")]
        
        # remove excess columns
        dt[, c("Stem_ge9",
               "Stem_6t9",
               "Stem_4t6",
               "Branch",
               "Foliage",
               "CWD") := NULL]
        
        return(dt)
}
