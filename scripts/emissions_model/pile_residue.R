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

piled_k_const <- function(k_const, coEf = 0.721, per_ag = .892, per_gc = .108) {
        
        k_pile <- ((k_const * coEf) * per_ag) + (k_const * per_gc)
        
        return(k_pile)
}


pile_residue <- function(dt, timestep) {

        # load the lookup table for piled fuels
        lookup_pile <- fread("data/SERC/lookup_tables/piled_fuels.csv", 
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
        
        # update k values
        dt[, ":=" (pile_CWD_K = piled_k_const(CWD_K),
                   pile_FWD_K = piled_k_const(FWD_K),
                   pile_Foliage_K = piled_k_const(Foliage_K))]
        
        # calculate landing pile load
        dt[, pile_load := decay_fun(CWD,
                                    pile_CWD_K,
                                    timestep) + 
                   to_duff(CWD,
                           pile_CWD_K,
                           timestep) +
                   decay_fun(Branch_tonsAcre * Branch,
                             pile_FWD_K,
                             timestep) +
                   to_duff(Branch_tonsAcre * Branch,
                           pile_FWD_K,
                           timestep) +
                   decay_foliage(Foliage_tonsAcre * Foliage, 
                                 pile_Foliage_K,
                                 timestep,
                                 "foliage") +
                   decay_foliage(Foliage_tonsAcre * Foliage, 
                                 pile_Foliage_K, 
                                 timestep,
                                 "duff")]
        
        # remove excess columns
        dt[, c("Stem_ge9",
               "Stem_6t9",
               "Stem_4t6",
               "Branch",
               "Foliage",
               "CWD",
               "pile_CWD_K",
               "pile_FWD_K",
               "pile_Foliage_K") := NULL]
        
        return(dt)
}
