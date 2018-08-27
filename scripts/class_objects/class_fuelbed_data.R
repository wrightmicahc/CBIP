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
                    fuel_prop,
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

AddFuel <- function(x) {
        browser()
        addfuel <- function(load, add, prop) {
                fuel <- load + (add * prop)
                return(fuel)
        }
        zero_div <- function(x, y) {
                return(ifelse(x == 0 & y == 0, 0, x / y))
        }
        
        x@fuel_load$litter_loading = addfuel(x@fuel_load$litter_loading,
                                             x@residue$Foliage_tonsAcre, 
                                             x@fuel_prop$litter_prop)
        
        x@fuel_load$litter_depth = zero_div(x@fuel_load$litter_loading,
                                            x@fuel_prop$litter_ratio)
        
        x@fuel_load$one_hr_sound = addfuel(x@fuel_load$one_hr_sound,
                                           x@residue$Branch_tonsAcre, 
                                           x@fuel_prop$one_hr_sound_prop)
        
        x@fuel_load$ten_hr_sound = addfuel(x@fuel_load$ten_hr_sound,
                                           x@residue$Branch_tonsAcre, 
                                           x@fuel_prop$ten_hr_sound_prop)
        
        x@fuel_load$hun_hr_sound = addfuel(x@fuel_load$hun_hr_sound,
                                           x@residue$Branch_tonsAcre, 
                                           x@fuel_prop$hun_hr_sound_prop)
        
        x@fuel_load$oneK_hr_sound = addfuel(x@fuel_load$oneK_hr_sound,
                                           x@residue$Break_4t9_tonsAcre, 
                                           x@fuel_prop$oneK_hr_sound_prop)
        
        x@fuel_load$tenK_hr_sound = addfuel(x@fuel_load$tenK_hr_sound,
                                            x@residue$Break_ge9_tonsAcre, 
                                            x@fuel_prop$tenK_hr_sound_prop)
        
        x@fuel_load$tnkp_hr_sound = addfuel(x@fuel_load$tnkp_hr_sound,
                                            x@residue$Break_ge9_tonsAcre, 
                                            x@fuel_prop$tnkp_hr_sound_prop)
        
        return(x)
}
