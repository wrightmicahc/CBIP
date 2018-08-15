################################################################################
# This script creates an object class that stores the data necessary to run the
# consume model.
#
# slots:
# xy_coords: two column matrix with raster cell lat-long  
# fuelbed_number: FCCS fuelbed ID number
# fuel_load: FCCS fuel loading data with columns for fuel size class
# residue: harvest and treatment residues
# treatmet: silvaculture treatment 
# fuel moisture: data frame with columns for  97.5 percentile values for 10 and 
# 1,000-hr fuel moisture
# slope: % slope
# wind: uncorrected windspeed
# tpi: normalized terrain prominance index
# pulp_market: is pulp market present?
# days_since_rain: the number of days since 0.25" rainfall
#
# author: Micah Wright
# 
################################################################################
setClass("fuelbed_data",
         
         slots = c(xy_coords = "matrix",
                   fuelbed_number = "integer",
                   fcid2018 = "integer",
                   fuel_load = "data.frame",
                   residue = "data.frame",
                   treatment = "character",
                   fm1000 = "numeric",
                   fm10 = "numeric",
                   slope = "numeric",
                   wind = "numeric",
                   tpi = "numeric",
                   pulp_market = "logical",
                   days_since_rain = "integer",
                   fm_type = "character")
)
