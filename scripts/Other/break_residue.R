################################################################################
# This script loads the UW residue data and calculates treatment-specific
# beakage and converts to tons/acre as part of the California Biopower Impact
# Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# load the necessary packages
library(data.table)
library(foreign)
library(tools)

# create a function to sum specified rows, remove or specify broken proportion, 
# and convert to tons/acre
sum_residue <- function(dt, columns, breakage, is_pulp) {
        
        if(!is_pulp) { net_res <- Reduce("+", dt[, columns, with = FALSE]) * breakage }
        
        if(is_pulp) { net_res <- Reduce("+", dt[, columns, with = FALSE]) * (1 - breakage) }
        
        return(net_res/2000)
}

# define function
break_residue <- function(treatment, harvest_type, harvest_system) {

        file_paths <- list("No_Action" = "data/UW/batch_out/Treatment_NoAction.dbf",
                           "Clearcut" = "data/UW/batch_out/Treatment_Remove100Percent.dbf",
                           "20_Thin_from_Above" = "data/UW/batch_out/Treatment_ThinFromAboveRemove20PercentBA.dbf",
                           "40_Thin_from_Above" = "data/UW/batch_out/Treatment_ThinFromAboveRemove40PercentBA.dbf",
                           "60_Thin_from_Above" = "data/UW/batch_out/Treatment_ThinFromAboveRemove60PercentBA.dbf",
                           "80_Thin_from_Above" = "data/UW/batch_out/Treatment_ThinFromAboveRemove80PercentBA.dbf",
                           "20_Thin_from_Below" = "data/UW/batch_out/Treatment_ThinFromBelowRemove20PercentBA.dbf",
                           "40_Thin_from_Below" = "data/UW/batch_out/Treatment_ThinFromBelowRemove40PercentBA.dbf",
                           "60_Thin_from_Below" = "data/UW/batch_out/Treatment_ThinFromBelowRemove60PercentBA.dbf",
                           "80_Thin_from_Below" = "data/UW/batch_out/Treatment_ThinFromBelowRemove80PercentBA.dbf",
                           "20_Proportional_Thin" = "data/UW/batch_out/Treatment_ThinProportionalRemove20PercentBA.dbf",
                           "40_Proportional_Thin" = "data/UW/batch_out/Treatment_ThinProportionalRemove40PercentBA.dbf",
                           "60_Proportional_Thin" = "data/UW/batch_out/Treatment_ThinProportionalRemove60PercentBA.dbf",
                           "80_Proportional_Thin" = "data/UW/batch_out/Treatment_ThinProportionalRemove80PercentBA.dbf",
                           "Standing_Dead" = "data/UW/batch_out/Treatment_Snags.dbf")
        
        if(treatment == "No_Action") {
   
                # load the file
                residue <- read.dbf(file_paths[[treatment]], as.is = TRUE)
                residue <- as.data.table(residue)
                residue[, Treatment := treatment]
                
                # update 
                broken_residue <- residue[, .(FCID2018 = Value,
                                              Treatment = Treatment,
                                              Harvest_type = harvest_type, 
                                              Harvest_system = harvest_system,
                                              TPA = TPA,
                                              Pulp_6t9_tonsAcre = 0.0,
                                              Break_6t9_tonsAcre = 0.0,
                                              Pulp_4t6_tonsAcre = 0.0,
                                              Break_4t6_tonsAcre = 0.0,
                                              Break_ge9_tonsAcre = 0.0,
                                              Branch_tonsAcre = 0.0,
                                              Foliage_tonsAcre = 0.0)]
        }
        
        if(treatment != "No_Action") {
                if(harvest_type == "Whole_Tree" & harvest_system == "Ground") {
                        breakage <- 0.14
                }
                
                if(harvest_type == "Whole_Tree" & harvest_system == "Cable") {
                        breakage <- 0.17
                }
                
                if(harvest_type == "Cut_to_Length" & harvest_system %in% c("Cable", "Ground")) {
                        breakage <- 0.10
                }
                
                
                # load the file
                residue <- read.dbf(file_paths[[treatment]], as.is = TRUE)
                residue <- as.data.table(residue)
                residue[, Treatment := treatment]
                
                # update 
                broken_residue <- residue[, .(FCID2018 = Value,
                                              Treatment = Treatment,
                                              Harvest_type = harvest_type, 
                                              Harvest_system = harvest_system,
                                              TPA = TPA,
                                              Pulp_6t9_tonsAcre = sum_residue(dt = residue,
                                                                              columns = c("CutStem6BL",
                                                                                          "CutBarkSte"),
                                                                              breakage = breakage,
                                                                              is_pulp = TRUE),
                                              Break_6t9_tonsAcre = sum_residue(dt = residue,
                                                                               columns = c("CutStem6BL",
                                                                                           "CutBarkSte"),
                                                                               breakage = breakage,
                                                                               is_pulp = FALSE),
                                              Pulp_4t6_tonsAcre = sum_residue(dt = residue,
                                                                              columns = c("CutStem4To",
                                                                                          "CutBarkS_2"),
                                                                              breakage = breakage,
                                                                              is_pulp = TRUE),
                                              Break_4t6_tonsAcre = sum_residue(dt = residue,
                                                                               columns = c("CutStem4To",
                                                                                           "CutBarkS_2"),
                                                                               breakage = breakage,
                                                                               is_pulp = FALSE),
                                              Break_ge9_tonsAcre = sum_residue(dt = residue,
                                                                               columns = c("CutStem6BG",
                                                                                           "CutBarkS_1"),
                                                                               breakage = breakage,
                                                                               is_pulp = FALSE),
                                              Branch_tonsAcre = CutBranchB/2000,
                                              Foliage_tonsAcre = CutFoliage/2000)]
        }
        
        return(broken_residue)
}
        