################################################################################
# This script creates an object class that stores the output data from the
# consume model.
#
# slots:
# xy_coords: two column matrix with raster cell lat-long  
# fuelbed_number: FCCS fuelbed ID number
# fuel_load: FCCS fuel loading data with columns for fuel size class
# residue: harvest and treatment residues
# treatment: silvaculture treatment 
# consumption: data frame of Consume fuel consumption output
# emissions: data frame of Consume emissions output
#
# author: Micah Wright
# 
################################################################################
setClass("fuel_consumption",
         
         slots = c(xy_coords = "matrix",
                   fuelbed_number = "integer",
                   FCID2018 = "integer",
                   treatment = "character",
                   consumption = "data.frame",
                   emissions = "data.frame")
)