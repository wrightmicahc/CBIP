################################################################################
# This script runs the scenario emissions model on all tiles. This is part of 
# the CA Biopower Impact Project. This will take a long time...
#
# Currently reinstalls sf each time, because I don't have admin to install for 
# everyone. The elapsed time is saved as an rds file in the main wd.
#
# Author: Micah Wright, Humboldt State University
################################################################################

#Source the emisssions function 
source("scripts/emissions_model/run_all.R")

install.packages("sf")

# run the whole thing
time <- system.time(run_all(1))

# save the time
saveRDS(time, "time.rds")
