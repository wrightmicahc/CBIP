################################################################################
# This script adds a column to specifie a pile proportion for biomass residue as
# part of the California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

pile_residue <- function(dt, piled) {
        dt[, piled_prop := piled]
}
