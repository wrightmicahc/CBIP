################################################################################
# This script loads the raster and tabular data and combines them into a single
# data.table as part of the California Biopower Impact Project. 
# 
# scenario: character, scenario number with underscore. Example: "scenario_one".
# tile_number: numeric tile number.
#
# Author: Micah Wright, Humboldt State University
################################################################################

# source the raster list function
source("scripts/scenarios/get_raster_list.R")

# load the necessary packages
library(raster)
library(rgdal)
library(data.table)

# define function
load_data <- function(scenario, tile_number) {
        
        # file path to tile shapefile
        tile_path <- "data/Tiles/tiles"
        
        # file path to residue table
        residue_path <- "data/UW/Residue_by_treat.csv" 
        
        # file path to fuel proportion table, used to divide residue 
        fuel_prop_path <- "data/FCCS/tabular/FCCS_fuel_load_proportions.csv"
        
        # file path to FCCS fuelbed table
        fuelbed_path <- "data/FCCS/tabular/FCCS_fuelbed.csv"
        
        # raster file paths
        raster_path <- get_raster_list(scenario)
                
        # check raster input
        stopifnot(is.list(raster_path), length(raster_path) == 7) 
        
        # function to load and crop raster to tile
        get_raster_fun <- function(x, poly){
                r <- raster(x)
                rc <- crop(r, poly)
                return(rc)
        }
        
        # split tile path into it's constituent components
        tile_path <- strsplit(tile_path, "/")
        
        # get depth of file structure
        tile_path_length <- length(tile_path[[1]]) 
        
        # load tiles
        tiles <- readOGR(paste(tile_path[[1]][1], 
                               tile_path[[1]][tile_path_length - 1],
                               sep = "/"),
                         tile_path[[1]][tile_path_length],
                         verbose = FALSE)
        
        # subset tiles
        tile <- tiles[tiles$ID == tile_number, ]
        
        # remove full tile polygon
        rm(tiles)
        
        # get list of raster paths
        rlist <- lapply(raster_path, function(x) get_raster_fun(x, tile))
        
        # load raster stack
        rstack <- stack(rlist)
        
        # remove raster file path list
        rm(rlist)
        
        # create data.table from stack
        rdf <- as.data.frame(rstack, 
                             xy = TRUE,
                             na.rm = TRUE) 
        
        rdf <- as.data.table(rdf)
        
        # remove stack
        rm(rstack)
        
        # remove any barren areas 
        rdf <- rdf[fuelbed_number < 900]
        
        # load fuel proportions
        fuel_prop <- fread(fuel_prop_path, 
                           verbose = FALSE) 
        
        # filter fuel proportions 
        fuel_prop <- fuel_prop[fuelbed_number %in% rdf$fuelbed_number]
        
        # load residue data
        residue <-  fread(residue_path,
                          verbose = FALSE) 
        
        # filter residue data
        residue <- residue[FCID2018 %in% rdf$FCID2018]
        
        # calculate total biomass load
        # Does not include foliage, which is assumed to be litter and not
        # recoverable
        residue$total_load <- rowSums(residue[, c("Break_ge9_tonsAcre",
                                                  "Branch_tonsAcre",
                                                  "Break_4t9_tonsAcre",
                                                  "Pulp_4t9_tonsAcre")])
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
