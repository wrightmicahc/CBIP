################################################################################
# This script contains unit tests for break_residue.R
#
# Author: Micah Wright, Humboldt State University
################################################################################

# source functions
source("scripts/Other/break_residue.R")

# load the clearcut dataset to test against
clrcut <- foreign::read.dbf("data/UW/batch_out/Treatment_Remove100Percent.dbf",
                            as.is = TRUE)
# change to data.table
clrcut <- as.data.table(clrcut)

# select first row
clrcut <- clrcut[1, ]

# update by hand, as if it was whole tree ground (breakage 0.14)
proof <- clrcut[, .(FCID2018 = Value,
                    Treatment = "Clearcut",
                    TPA = TPA,
                    Pulp_6t9_tonsAcre = ((CutStem6BL + CutBarkSte) * (1 - 0.14))/2000,
                    Break_6t9_tonsAcre = ((CutStem6BL + CutBarkSte) * 0.14)/2000,
                    Pulp_4t6_tonsAcre = ((CutStem4To + CutBarkS_2) * (1 - 0.14))/2000,
                    Break_4t6_tonsAcre = ((CutStem4To + CutBarkS_2) * 0.14)/2000,
                    Break_ge9_tonsAcre = ((CutStem6BG + CutBarkS_1) * 0.14)/2000,
                    Branch_tonsAcre = CutBranchB/2000,
                    Foliage_tonsAcre = CutFoliage/2000)]

# burn pile
test <- break_residue("Clearcut", "Whole_Tree", "Ground")

all.equal(test[1,], proof)
