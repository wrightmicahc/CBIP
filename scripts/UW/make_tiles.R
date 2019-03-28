################################################################################
# This script makes custom tiles and saves to a file
# 
# Author: Micah Wright
# Date: 06/07/2018
################################################################################

# Setup: Load the necessary packages
library(raster)
library(rgdal)

# grab one of the necessary rasters
FCID <- raster("data/UW/UW_FCID.tif")

# make a function that creates a list of extents that fall within an existing 
# extent object. needs a raster and the number of tiles in the x-y dimensions
SplitRas <- function(r, numtiles_x, numtiles_y) {
        # make a master extent
        rbounds <- as.matrix(extent(r))
        
        # make a data frame with the coordinates in between current extent limits
        coord_df <- data.frame(x = seq(rbounds[1, 1], 
                                       rbounds[1, 2], 
                                       length.out = numtiles_x),
                               y = seq(rbounds[2, 1],
                                       rbounds[2, 2], 
                                       length.out = numtiles_y))
        
        # make a list of all the extents within the master extent
        ext_List <- unlist(lapply(seq(1:(nrow(coord_df)-1)), function(i)
                lapply(seq(1:(nrow(coord_df)-1)), function(j) 
                        extent(coord_df$x[i], coord_df$x[i + 1],
                               coord_df$y[j], coord_df$y[j + 1]))
                ))
        
        return(ext_List)
}

# make a bunch of extents
ext_list <- SplitRas(FCID, 200, 200)

# function to make the extents spatialpolygons
CreatePoly <- function(ext) {
        #browser()
        p <- as(ext, "SpatialPolygons")
        return(p)
}

# create a list of spatialpolygons
poly_list <- lapply(seq(1:length(ext_list)), 
                    function(i) CreatePoly( ext_list[[i]]))

# merge to one big poly
poly <- do.call(bind, poly_list) 

# define projection
proj4string(poly) <- crs(FCID)

# load srtm to clip
srtm <- readOGR("data/Other/srtm_1_deg",
                "srtm_1_deg")

# reproject
srtm <- spTransform(srtm, proj4string(poly))

# crop extents to CA and srtm, otherwise the tiles go into Oregon
poly <- poly[srtm, ]

# check with a plot
plot(poly)

# how big are the tiles?
area_fun <- function(shp) {
        cat("Area: ", area(shp)/10000, " Hectares")
}

area_fun(poly[1])

# Remove any old tiles to avoid overwrite issues
lapply(list.files("data/Tiles/raw_tiles", full.names = TRUE), file.remove)

# save the polygons
shapefile(poly, "data/Tiles/raw_tiles/raw_tiles.shp", overwrite=TRUE)

