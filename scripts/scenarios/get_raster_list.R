################################################################################
# This script selects the file paths for raster data based on burn scenario name 
#
# Author: Micah Wright, Humboldt State University
################################################################################

get_raster_list <- function(scenario, conditions) {
        
        stopifnot(scenario %in% c("None", 
                                  "Pile", 
                                  "Broadcast", 
                                  "Jackpot"))
        
        if(scenario == "None" & conditions == "Average") 
        {
                files <- list("FCID2018" = "data/UW/FCID2018_masked.tif",
                              "Slope" = "data/Other/DEM/Slope_NAD83.tif",
                              "fuelbed_number" = "data/FCCS/spatial/FCCS_NAD83.tif", 
                              "Fm10" = "data/GEE/resampled/fm10_50.tif",
                              "Fm1000" = "data/GEE/resampled/fm1000_50.tif",
                              "Wind" = "data/GEE/resampled/windv_50.tif",
                              "TPI" = "data/Other/DEM/dem_dev_2g_NAD83.tif")
        }
        
        if(scenario == "None" & conditions == "Extreme") 
        {
                files <- list("FCID2018" = "data/UW/FCID2018_masked.tif",
                              "Slope" = "data/Other/DEM/Slope_NAD83.tif",
                              "fuelbed_number" = "data/FCCS/spatial/FCCS_NAD83.tif", 
                              "Fm10" = "data/GEE/resampled/fm10_97.tif",
                              "Fm1000" = "data/GEE/resampled/fm1000_97.tif",
                              "Wind" = "data/GEE/resampled/windv_97.tif",
                              "TPI" = "data/Other/DEM/dem_dev_2g_NAD83.tif")
        }
        
        if(scenario %in% c("Pile", "Broadcast", "Jackpot")) 
        {
                files <- list("FCID2018" = "data/UW/FCID2018_masked.tif",
                              "Slope" = "data/Other/DEM/Slope_NAD83.tif",
                              "fuelbed_number" = "data/FCCS/spatial/FCCS_NAD83.tif", 
                              "Fm10" = "data/GEE/resampled/fm10_375.tif",
                              "Fm1000" = "data/GEE/resampled/fm1000_375.tif",
                              "Wind" = "data/GEE/resampled/windv_375.tif",
                              "TPI" = "data/Other/DEM/dem_dev_2g_NAD83.tif")
        }
        
        return(files)
}
