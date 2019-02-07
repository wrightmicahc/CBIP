################################################################################
# This script creates a mask layer for the cells with an FCCS identifier of 0 
# or otherwise barren. The mask will be used to select forested pixels as of the
# California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load the necessary packages
library(data.table)
library(raster)

# load the fccs file with loads optimized for consume
dt_fccs <- fread("data/FCCS/tabular/LF_consume.csv", 
                 skip = 1, 
                 header = TRUE)

# load the fccs file with total loads and descriptions
fccs_descript <- fread("data/FCCS/tabular/FCCS_02102017.csv")

fccs_descript <- fccs_descript[Value != -9999, .(fuelbed_number = Value,
                                   fuelbed_name = Fuelbed_Na)]
# merge the files
dt_fccs <- merge(dt_fccs, fccs_descript, by = "fuelbed_number", all = TRUE)

# load FCCS raster
FCCS <- raster("data/FCCS/spatial/FCCS_NAD83.tif")

# get the fuelbed numbers that don't have any canopy fuels
# or are between 900 & 1000
fccs_notrees <- dt_fccs[fuelbed_number %in% c(0, seq(900, 999, 1)), .(fuelbed_number)][["fuelbed_number"]]

# create a column for updated pixel value based on the FCCS ID
dt_fccs[, becomes := ifelse(fuelbed_number %in% fccs_notrees, 1, NA)]

# save the fuelbed names that will be removed
fwrite(dt_fccs[becomes == 1, .(fuelbed_name)], "data/FCCS/tabular/fuelbeds_removed.csv")

# create a reclass matrix from the dt
rcl <- as.matrix(dt_fccs[, .(fuelbed_number, becomes)])

# reclassify the FCID raster
FCCS_recl <- reclassify(FCCS, rcl)

# remove old raster to avoid overwrite issues
file.remove("data/FCCS/spatial/FCCS_unforested.tif")

# save the output
writeRaster(FCCS_recl,
            "data/FCCS/spatial/FCCS_unforested.tif",
            format = "GTiff",
            datatype = "INT2S")

# get the cell count summarys for both rasters and save them.
cell_counts_FCCS <- as.data.table(freq(FCCS_recl))

fwrite(cell_counts_FCCS, "data/FCCS/tabular/cell_counts_FCCS.csv")

