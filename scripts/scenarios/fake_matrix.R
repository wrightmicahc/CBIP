################################################################################
#                        !!!!!!for testing only!!!!!
# This script makes a fake scenario matrix for testing. Does not actually 
# conform to logic for real scenario matrix. This is part of the CA Biopower
# Impact Project.
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load packages
library(data.table)

# create fake scenario matrix with all combinations of options                                           
fake_mat <- expand.grid(Silvicultural_Treatment = c("Clearcut",
                                              "20_Thin_from_Below",
                                              "40_Thin_from_Below",
                                              "60_Thin_from_Below",
                                              "80_Thin_from_Below",
                                              "20_Thin_from_Above",
                                              "40_Thin_from_Above",
                                              "60_Thin_from_Above",
                                              "80_Thin_from_Above",
                                              "20_Proportional_Thin",
                                              "40_Proportional_Thin",
                                              "60_Proportional_Thin",
                                              "80_Proportional_Thin",
                                              "Standing_Dead",
                                              "No_Action"),
                        Slope_Class = c(40, 80),
                  Fraction_Piled = c(0, 0.3, 0.5, 0.7),
                  Burn_Type = c("Pile", 
                                "Broadcast",
                                "None"),
                  Biomass_Collection = c("Pile",
                                         "Pile_Scattered",
                                         "None"),
                  Pulp_Market = c("Yes", 
                                  "No"))
# convert to data.table
fake_mat <- as.data.table(fake_mat)
            
# calculate fraction scattered
fake_mat[, Fraction_Scattered := 1 - Fraction_Piled][, ID := 1:.N, by = "Slope_Class"]

# make columns. These are all the same, just for testing.
# these do not match the scattered and piled id columns
col_prefix <- c("Stem_ge9", "Stem_6t9", "Stem_4t6", "Branch", "Foliage")
col_suffix <- c("recovered", "scattered", "piled")
fake_mat[, paste(rep(col_prefix, length(col_suffix)), col_suffix, sep = "_") := 1/15]
 
# save the fake scenario matrix
fwrite(fake_mat[Slope_Class == 40, .(ID, 
                    Silvicultural_Treatment,
                    Fraction_Piled,
                    Fraction_Scattered,
                    Burn_Type,
                    Biomass_Collection,
                    Pulp_Market)], "data/SERC/fake_scenarios.csv")

lapply(col_suffix, function(x) {
        
        fwrite(fake_mat[, .(ID, 
                            Silvicultural_Treatment,
                            Fraction_Piled,
                            Fraction_Scattered,
                            Burn_Type,
                            Biomass_Collection,
                            Pulp_Market,
                            Slope_Class,
                            Stem_ge9 = get(paste("Stem_ge9", x, sep = "_")),
                            Stem_6t9 = get(paste("Stem_6t9", x, sep = "_")),
                            Stem_4t6 = get(paste("Stem_4t6", x, sep = "_")),
                            Branch = get(paste("Branch", x, sep = "_")),                
                            Foliage = get(paste("Foliage", x, sep = "_")))], 
               paste0("data/SERC/lookup_tables/fake/", 
                      x, 
                      ".csv"))
})

     