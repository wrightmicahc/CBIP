################################################################################
# This script uses the dbh and height to calculate tree crown loads using 
# biomass ratio equations from Jenkins et al. 2003, "National-scale biomass 
# estimators for United States tree species". This is part of the CA Biopower 
# Impact Project.
#
# Author: Micah Wright, Humboldt State University
################################################################################

# tree class lookup. Hardcoded from data/UW/Species.xlsx
treeclass <- list("hardwood" = c("AL", "AS", "BH", "BK", "BL", "BM", "BO", 
                                 "BT", "BU", "CA", "CH", "CK", "CL", "CN", 
                                 "CW", "CY", "DG", "DI", "EM", "EO", "FC",
                                 "FL", "GC", "HM", "HT", "IO", "LO", "MA", 
                                 "MC", "MM", "NC", "OA", "OH", "OR", "OT", 
                                 "OX", "PB", "PL", "RA", "RP", "SB", "SM", 
                                 "SU", "SY", "TH", "TO", "VA", "VN", "VO",
                                 "WA", "WI", "WN", "WO", "WT"),
                  "softwood" = c("AF", "BC", "BD", "BP", "BR", "CC", "CJ", 
                                 "CP", "CU", "DF", "ES", "FP", "GB", "GF",
                                 "GP", "GS", "IC", "JP", "KP", "LL", "LM", 
                                 "LP", "MH", "MO", "MP", "NF", "OS", "PC",
                                 "PM", "PP", "PY", "RC", "RF", "RM", "RW", 
                                 "SP", "SF", "SH", "UJ", "WB", "WE", "WF",
                                 "WH", "WJ", "WL", "WP"))
# coefficients lookup
comp_coef <- list("hardwood" = list("foliage" = c("b0" = -4.0813,
                                                  "b1" = 5.8816),
                                    "roots" = c("b0" = -1.6911,
                                                "b1" = 0.8160),
                                    "stem_bark" = c("b0" = -2.0129,
                                                    "b1" = -1.6805),
                                    "stem_wood" = c("b0" = -0.3065,
                                                    "b1" = -5.4240)),
                  "softwood" = list("foliage" = c("b0" = -2.9584,
                                                  "b1" = 4.4766),
                                    "roots" = c("b0" = -1.5619,
                                                "b1" = 0.6614),
                                    "stem_bark" = c("b0" = -2.0980,
                                                    "b1" = -1.1432),
                                    "stem_wood" = c("b0" = -0.3737,
                                                    "b1" = -1.8055)))

calc_ratio <- function(spp, dbh, compcl) {
        
        # error checking
        stopifnot(compcl %in% c("foliage", "roots", "stem_bark", "stem_wood"),
                  spp %in% treeclass[["hardwood"]] | spp %in% treeclass[["softwood"]],
                  is.numeric(dbh))
        
        # component ratio equation from Jenkins
        rat_fun <- function(b0, b1, dbh) {
                signif(exp(b0 + (b1/(dbh * 2.54))), digits = 3) 
        }
        
        cmp_ratio <- ifelse(spp %in% treeclass[["hardwood"]],
                            rat_fun(comp_coef[["hardwood"]][[compcl]]["b0"],
                                    comp_coef[["hardwood"]][[compcl]]["b1"],
                                    dbh),
                            rat_fun(comp_coef[["softwood"]][[compcl]]["b0"],
                                    comp_coef[["softwood"]][[compcl]]["b1"],
                                    dbh))
        
        return(cmp_ratio)
}
