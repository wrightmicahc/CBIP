################################################################################
# This script corrects windspeed for FCCS fuelbeds based on terrain and trees 
# per acre as part of the  California Biopower Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

wind_correction <- function(wind, tpa, tpi) {
        
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
        
        # classify landform based on terrain prominence
        lf_class <- ifelse(tpi < -0.5, "valley", 
                           ifelse(tpi >= -0.5 & tpi < 0, 
                                  "lower_slope",
                                  ifelse(tpi >= 0 & tpi < 0.5,
                                         "upper_slope",
                                         "ridge")))
        
        # classify shelter based on tpa
        shelter_class <- ifelse(tpa <= 10, 
                                "unsheltered",
                                ifelse(tpa > 10 & tpa <= 100,
                                       "partially_sheltered",
                                       "sheltered"))
        
        waf <- waf_dict[[lf_class]][[shelter_class]]
        
        wind_corrected <- wind * waf
        
        return(wind_corrected)
}
