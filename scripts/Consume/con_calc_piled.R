################################################################################
# This script calculates emissions for piled woody fuels as part of the
# California Biopower Impact Project for the CARBCAT model.It is loosely based 
# on consume 4.2, which is distributed within fuel fire tools. W
# 
# Author: Micah Wright, Humboldt State University
#
# 
################################################################################

con_calc_piled <- function(pile_load) {
        # emissions factors from consume, clean only
        emission_factors <- c("PM" = 21.9, 
                             "PM10" = 15.5,
                             "PM25" = 13.5,
                             "CO" = 52.66,
                             "CO2" = 3429.24, 
                             "CH4" = 3.28, 
                             "NMHC" = 3.56)
        
        return((pile_load * 0.9) * emission_factors) 
}