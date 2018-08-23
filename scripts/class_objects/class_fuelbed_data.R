################################################################################
# This script creates an object class that stores the data necessary to run the
# consume model.
#
# slots:
# xy_coords: two column matrix with raster cell lat-long
# fuelbed_number: FCCS fuelbed ID number
# fcid2018: updated GNN FCID 
# fuel_load: FCCS fuel loading data with columns for each fuel size class
# residue: harvest and treatment residue data frames
# treatment: silvaculture treatment
# fm1000: 97.5 percentile value for 1,000-hr fuel moisture
# fm10: 97.5 percentile value for 10-hr fuel moisture
# slope: % slope
# wind: uncorrected windspeed
# tpi: normalized terrain prominance index
# pulp_market: is there a pulp market?
# days_since_rain: the number of days since 0.25" rainfall
# fm_type: fuel moisture adjustment class
#
# author: Micah Wright
#
################################################################################

.Fuelbed <- setClass("Fuelbed",
                     #contains = "FuelLoad",
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

Fuelbed <- function(xy_coords,
                    fuelbed_number,
                    fcid2018, 
                    fuelbed, 
                    residue,
                    treatment,
                    fm1000, 
                    fm10,
                    slope, 
                    wind, 
                    tpi,
                    pulp_market,
                    days_since_rain,
                    fm_type) {
        
        .Fuelbed(xy_coords = xy_coords,
                 fuelbed_number = fuelbed_number,
                 fcid2018 = fcid2018,
                 treatment = treatment,
                 fuel_load = fuelbed[fuelbed$fuelbed_number == fuelbed_number, ],
                 residue = residue[residue$FCID2018 == fcid2018 &
                                           residue$Treatment == treatment, ],
                 fm1000 = fm1000,
                 fm10 = fm10,
                 slope = slope,
                 wind = wind,
                 tpi = tpi,
                 pulp_market = pulp_market,
                 days_since_rain = days_since_rain,
                 fm_type = fm_type)
}

