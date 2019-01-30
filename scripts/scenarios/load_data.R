################################################################################
# This script loads the raster and tabular data and combines them into a single
# data.table as part of the California Biopower Impact Project. 
# 
# scenario: character, rx burn scenario. Either "none", "pile", "broadcast", or
# "jackpot".
# tile_number: numeric tile number.
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load the necessary packages
library(data.table)

# define function
load_data <- function(id, treatment, harvest_system, harvest_type, burn_type, biomass_collection, tile_number) {
        
        # file path to residue tables
        residue_path <- list("No_Action" = "data/UW/residue/NoAction.csv",
                             "Clearcut" = "data/UW/residue/Remove100Percent.csv",
                             "20_Thin_from_Above" = "data/UW/residue/ThinFromAboveRemove20PercentBA.csv",
                             "40_Thin_from_Above" = "data/UW/residue/ThinFromAboveRemove40PercentBA.csv",
                             "60_Thin_from_Above" = "data/UW/residue/ThinFromAboveRemove60PercentBA.csv",
                             "80_Thin_from_Above" = "data/UW/residue/ThinFromAboveRemove80PercentBA.csv",
                             "20_Thin_from_Below" = "data/UW/residue/ThinFromBelowRemove20PercentBA.csv",
                             "40_Thin_from_Below" = "data/UW/residue/ThinFromBelowRemove40PercentBA.csv",
                             "60_Thin_from_Below" = "data/UW/residue/ThinFromBelowRemove60PercentBA.csv",
                             "80_Thin_from_Below" = "data/UW/residue/ThinFromBelowRemove80PercentBA.csv",
                             "20_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove20PercentBA.csv",
                             "40_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove40PercentBA.csv",
                             "60_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove60PercentBA.csv",
                             "80_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove80PercentBA.csv",
                             "Standing_Dead" = "data/UW/residue/Snags.csv")
        
        # file path to fuel proportion table, used to divide residue 
        fuel_prop_path <- "data/FCCS/tabular/FCCS_fuel_load_proportions.csv"
        
        # file path to FCCS fuelbed table
        fuelbed_path <- "data/FCCS/tabular/FCCS_fuelbed.csv"
        
        # FCID with no residue
        nores_path <- "data/UW/FCID_no_residue.csv"
        
        if(burn_type == "None") {
                
                rdf <- readRDS(paste0("data/Tiles/wildfire/", 
                                    tile_number, ".rds"))
                
        }
        
        if(burn_type %in% c("Pile", "Broadcast", "Jackpot")) {
                
                rdf <- readRDS(paste0("data/Tiles/rx/", 
                                    tile_number, ".rds"))
                
        }
        
        # remove any barren areas 
        rdf <- rdf[fuelbed_number < 900]
        
        # load lookup of FCID without residue
        nores <- fread(nores_path, 
                       verbose = FALSE)
        
        # remove any FCID with no residue
        rdf <- rdf[!(FCID2018 %in% nores$FCID2018)]
        
        # load fuel proportions
        fuel_prop <- fread(fuel_prop_path, 
                           verbose = FALSE) 
        
        # filter fuel proportions 
        fuel_prop <- fuel_prop[fuelbed_number %in% rdf$fuelbed_number]
        
        # load residue data
        residue <- fread(residue_path[[treatment]], verbose = FALSE)
        
        # filter residue data
        residue <- residue[FCID2018 %in% rdf$FCID2018]
        
        # specify treatment etc.
        residue[, `:=`(ID = id,
                       Silvicultural_Treatment = treatment, 
                       Harvest_System = harvest_system,
                       Harvest_Type = harvest_type, 
                       Burn_Type = burn_type,
                       Biomass_Collection = biomass_collection,
                       Tile_Number = tile_number)]
        
        # merge data 
        rdf <- merge(rdf, fuel_prop, by = "fuelbed_number")
        
        fuel_df <- merge(rdf, residue, by = "FCID2018", allow.cartesian = TRUE)
        
        # remove unnecessary data
        rm(fuel_prop)
        
        rm(residue)
        
        rm(rdf)
        
        # load FCCS fuelbed data and join
        FCCS <- fread(fuelbed_path, verbose = FALSE)
        
        fuel_df <-  merge(fuel_df, FCCS, by = "fuelbed_number")
        
        return(fuel_df)
}
