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

.Fuelbed <- setClass("Fuelbed",
                     
                     slots = c(xy_coords = "matrix",
                               fuelbed_number = "integer",
                               fcid2018 = "integer",
                               fuel_load = "data.frame",
                               fuel_prop = "data.frame",
                               residue = "data.frame",
                               treatment = "character",
                               bio_rm = "numeric",
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
                    bio_rm,
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
                 bio_rm = bio_rm,
                 fuel_load = fuelbed[fuelbed$fuelbed_number == fuelbed_number, ],
                 fuel_prop = fuel_prop[fuel_prop$fuelbed_number == fuelbed_number, ],
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

setMethod("show", "Fuelbed", function(object) {
        cat(is(object)[[1]], "\n",
            " Fuelbed Number: ", object@fuelbed_number, "\n", 
            " FCID (2018): ", object@fcid2018, "\n",
            #" Fuel Load: ", object@fuel_load, "\n",
            #" Treatment Residue: ", object@residue, "\n",
            " Treatment: ", object@treatment, "\n",
            " Biomass Removed: ", object@bio_rm, "\n",
            # " 1,000-hr Fuel Moisture: ", object@fm1000, "\n",
            # " 10-hr Fuel Moisture: ", object@fm10, "\n",
            # " % Slope: ", object@slope, "\n",
            # " Windspeed (m/sec): ", object@wind, "\n",
            # "Terrain Prominence: ", object@tpi, "\n",
            " Pulp Market: ", object@pulp_market, "\n",
            " Fuel Moisture Type: ", object@fm_type, "\n",
            sep = "")
})
