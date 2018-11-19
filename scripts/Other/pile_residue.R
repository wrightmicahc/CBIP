################################################################################
# This script adds a column to specify a pile proportion for biomass residue as
# part of the California Biopower Impact Project. 
# 
# Currently, it is assumed that foliage is piled along with the branches
#
# Author: Micah Wright, Humboldt State University
################################################################################

pile_residue <- function(dt, pm) {
        
        pile_prop <- function(tp, syst) {
                gets_piled <- ifelse(tp == "Whole_Tree" & syst == "Ground", 
                                     0.7,
                                     ifelse(tp == "Whole_Tree" & syst == "Cable",
                                            0.6, 0.0)) 
                return(gets_piled)
        }
        
        if(pm == "present") {
                
                dt[, pile_landing := (Break_4t6_tonsAcre +
                                           Break_6t9_tonsAcre +
                                           Branch_tonsAcre +
                                           Break_ge9_tonsAcre +
                                           Foliage_tonsAcre) *
                           pile_prop(Harvest_type,
                                     Harvest_system)]
                
        }
        
        if(pm == "absent") {
                
                dt[, pile_landing := (Break_4t6_tonsAcre +
                                           Break_6t9_tonsAcre +
                                           Branch_tonsAcre +
                                           Break_ge9_tonsAcre +
                                           Pulp_4t6_tonsAcre +
                                           Pulp_6t9_tonsAcre +
                                           Foliage_tonsAcre) *
                           pile_prop(Harvest_type,
                                     Harvest_system)]
                
        }
        
        return(dt)
}
