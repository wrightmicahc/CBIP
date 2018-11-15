################################################################################
# This script adds a column to specify a pile proportion for biomass residue as
# part of the California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

pile_residue <- function(h_type, h_system) {
        browser()
        
        piled <- ifelse(h_type == "Whole_Tree" & h_system == "Ground", 0.7,
                        ifelse(h_type == "Whole_Tree" & h_system == "Cable", 0.6, 0.0))  
        
        return(piled)
}
