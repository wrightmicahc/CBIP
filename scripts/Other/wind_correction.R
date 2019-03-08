################################################################################
# This script corrects windspeed for FCCS fuelbeds based on terrain and trees 
# per acre as part of the  California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

wind_correction <- function(dt, Wind, TPA, TPI) {
        
        # make a nested list of wind adjustment factors
        waf_dict <- list("ridge" = list("unsheltered" = 0.5,
                                        "partially_sheltered" = 0.4,
                                        "sheltered" = 0.3),
                         "upper_slope" = list("unsheltered" = 0.5,
                                              "partially_sheltered" = 0.4,
                                              "sheltered" = 0.3),
                         "lower_slope" = list("unsheltered" = 0.5,
                                              "partially_sheltered" = 0.3,
                                              "sheltered" = 0.2),
                         "valley" = list("unsheltered" = 0.5,
                                         "partially_sheltered" = 0.2,
                                         "sheltered" = 0.1))
        
        # write function to access waf_dict for each row based on lf_class and 
        # shelter_class
        make_waf <- function(lf_class, shelter_class) {
                z <- lapply(seq(1:length(lf_class)), function(i)
                        waf_dict[[lf_class[i]]][[shelter_class[i]]])
                
                return(unlist(z))
        }
        
        # classify landform based on terrain prominence
        dt[, lf_class := ifelse(TPI < -0.5, "valley", 
                                ifelse(TPI >= -0.5 & TPI < 0, 
                                       "lower_slope",
                                       ifelse(TPI >= 0 & TPI < 0.5,
                                              "upper_slope",
                                              "ridge")))]
        
        # classify shelter based on tpa
        dt[, shelter_class := ifelse(TPA <= 10, 
                                     "unsheltered",
                                     ifelse(TPA > 10 & TPA <= 100,
                                            "partially_sheltered",
                                            "sheltered"))]
        
        # get waf
        dt[, waf := make_waf(lf_class, shelter_class)]
        
        # correct windspeed
        dt[, ':=' (Wind_corrected_rx = Wind_rx * waf,
                   Wind_corrected_50 = Wind_50 * waf,
                   Wind_corrected_97 = Wind_97 * waf)]
        
        # remove old columns
        dt[, c("lf_class", "shelter_class", "waf") := NULL ]
        
}
