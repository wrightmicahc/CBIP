################################################################################
# Make a raster of total UW residue as part of the California Biopower Impact 
# Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load the necessary packages
library(data.table)
library(raster)

# load the fccs file with total loads and descriptions
dt_fccs <- fread("data/FCCS/tabular/FCCS_02102017.csv")

# load FCID raster
FCID <- raster("data/UW/FCID2018_masked.tif")

# load the residue data for the clearcut treatment
clearcut <- fread("data/UW/residue/Remove100Percent.csv")

# calculate total residue
clearcut[, total_res := Stem_6t9_tonsAcre + Stem_4t6_tonsAcre + Stem_ge9_tonsAcre + Branch_tonsAcre + Foliage_tonsAcre]

# create a reclass matrix from the dt
rcl_FCID <- as.matrix(clearcut[, .(FCID2018, total_res)])

# reclassify the FCID raster, assigning total residue to each pixel
FCID_rcl <- reclassify(FCID, rcl_FCID)

# save the output
writeRaster(FCID_rcl,
            "data/UW/UW_FCID_no_wild_total_res.tif",
            format = "GTiff")
