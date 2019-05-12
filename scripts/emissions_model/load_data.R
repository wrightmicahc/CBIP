################################################################################
# This script loads the residue, fuelbed, and location attribute data and 
# combines them into a single data.table as part of the California Biopower 
# Impact Project. 
# 
# burn_type: None (wf), Broacast, Pile, or Jackpot
# biomass_collection: yes/no
# tile_number: numeric tile number.
#
# Author: Micah Wright, Humboldt State University
################################################################################

# define function
load_data <- function(id, treatment, f_piled, f_scattered, burn_type, biomass_collection, pulp_market, tile_number) {
        
        # file paths to residue tables
        residue_path <- list("No_Action" = "data/UW/residue/NoAction.csv",
                             "Clearcut" = "data/UW/residue/Remove100Percent.csv",
                             "20_Thin_From_Above" = "data/UW/residue/ThinFromAboveRemove20PercentBA.csv",
                             "40_Thin_From_Above" = "data/UW/residue/ThinFromAboveRemove40PercentBA.csv",
                             "60_Thin_From_Above" = "data/UW/residue/ThinFromAboveRemove60PercentBA.csv",
                             "80_Thin_From_Above" = "data/UW/residue/ThinFromAboveRemove80PercentBA.csv",
                             "20_Thin_From_Below" = "data/UW/residue/ThinFromBelowRemove20PercentBA.csv",
                             "40_Thin_From_Below" = "data/UW/residue/ThinFromBelowRemove40PercentBA.csv",
                             "60_Thin_From_Below" = "data/UW/residue/ThinFromBelowRemove60PercentBA.csv",
                             "80_Thin_From_Below" = "data/UW/residue/ThinFromBelowRemove80PercentBA.csv",
                             "20_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove20PercentBA.csv",
                             "40_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove40PercentBA.csv",
                             "60_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove60PercentBA.csv",
                             "80_Proportional_Thin" = "data/UW/residue/ThinProportionalRemove80PercentBA.csv",
                             "Standing_Dead" = "data/UW/residue/Snags.csv")
        
        # file path to fuel proportion table, used to divide residue 
        fuel_prop_path <- "data/FCCS/tabular/FCCS_fuel_load_proportions.csv"
        
        # file path to FCCS fuelbed table
        fuelbed_path <- "data/FCCS/tabular/FCCS_fuelbed.csv"
        
        # load tabulated spatial data for the tile
        rdf <- readRDS(paste0("data/Tiles/input/", 
                              tile_number, ".rds"))
        
        # remove slopes above 80%
        rdf <- rdf[Slope < 80]
        
        # load fuel proportions
        fuel_prop <- fread(fuel_prop_path, 
                           verbose = FALSE) 
        
        # filter fuel proportions to include only those in the current tile
        fuel_prop <- fuel_prop[fuelbed_number %in% rdf$fuelbed_number]
        
        # load residue data
        residue <- fread(residue_path[[treatment]], verbose = FALSE)
        
        # filter residue data to include only those in the current tile
        residue <- residue[FCID2018 %in% rdf$FCID2018]
        
        # specify scenario treatments and attributes
        residue[, ':=' (ID = id,
                        Silvicultural_Treatment = treatment, 
                        Fraction_Piled = f_piled,
                        Fraction_Scattered = f_scattered,
                        Burn_Type = burn_type,
                        Biomass_Collection = biomass_collection,
                        Pulp_Market = pulp_market,
                        Tile_Number = tile_number)]
        
        # merge tabulated raster data to fuel proportion and residue data 
        setkey(rdf, FCID2018)
        setkey(residue, FCID2018)
        rdf <- merge(rdf, residue, by = "FCID2018")
        
        setkey(rdf, fuelbed_number)
        setkey(fuel_prop, fuelbed_number)
        rdf <- merge(rdf, fuel_prop, by = "fuelbed_number")
        
        # remove data frames no longer needed
        rm(fuel_prop)
        
        rm(residue)
        
        # load FCCS fuelbed data and join to main data set
        FCCS <- fread(fuelbed_path, verbose = FALSE)
        
        setkey(FCCS, fuelbed_number)
        
        rdf <-  merge(rdf, FCCS, by = "fuelbed_number")
        
        # specify a slope class
        rdf[, Slope_Class := ifelse(Slope < 40, 40, 80)]
        
        return(rdf)
}
