################################################################################
# This script adds a column to specify a pile proportion for biomass residue as
# part of the California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

pile_residue <- function(dt, pm) {
        
        pile_prop <- function(tp, syst) {
                ifelse(tp == "Whole_Tree" & syst == "Ground", 0.7,
                       ifelse(tp == "Whole_Tree" & syst == "Cable", 0.6, 0.0)) 
        }
        
        if(pm == "present") {
                dt[, pile_load := (Break_4t6_tonsAcre + Break_6t9_tonsAcre) * pile_prop(Harvest_type,
                                                                         Harvest_system)]
        }
        
        if(pm == "absent") {
                dt[, pile_load := (Break_4t6_tonsAcre +
                                           Break_6t9_tonsAcre +
                                           Pulp_4t6_tonsAcre +
                                           Pulp_6t9_tonsAcre) * 
                           pile_prop(Harvest_type,
                                     Harvest_system)]
        }
        
        return(dt)
}
