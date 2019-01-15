################################################################################
# This script is an R translation of the woody fuels activity equations from
# consume 4.2, which is distributed within fuel fire tools. Whenever possible, 
# function, variable names, and comments from the original python script were
# preserved. This translation was performed as part of the California Biopower 
# Impact Project for the CARBCAT model. The code was modified to better match 
# the goals and geographic constraints of the project. Litter consumption
# equations and some generic functions are also included here.
# 
# Tanslator: Micah Wright, Humboldt State University
#
# 
################################################################################

# vector of quadratic mean diameters for 100, 1,000, 10,000, and >10,000 hour
# fuels
QMDs <- c(1.68, 5.22, 12.10, 25.00) 

# list of fuel moisture adjustment coefficients for different fuel moisture 
# measurement methods and seasons
# MEAS_Th: fuel moisture directly sampled
# NFDRS_Th: fuel moisture calculated using methods from National Fire Danger
# Rating System
# ADJ_Th: fuel moisture calculated using Adjusted 1000-hr fuel moisture
cdic <- list("spring" = list("MEAS_Th" = c(-0.097, 4.747),
                             "ADJ_Th" = c(-0.096, 4.6495),
                             "NFDRS_Th" = c(-0.120 / 1.4, 4.305)),
             "summer" = list("MEAS_Th" = c(-0.108, 5.68),
                             "ADJ_Th" = c(-0.1251, 6.27),
                             "NFDRS_Th" = c(-0.150 / 1.4, 5.58)),
             "adj" = list("MEAS_Th" = 1,
                          "ADJ_Th" = 1,
                          "NFDRS_Th" = 1.4))

# emissions factors data
ef_db <- list("flaming" = c("CH4" =  0.00382000,
                            "CO" = 0.07180000,
                            "CO2" = 1.64970000,
                            "NH3" = 0.00120640,
                            "NOx" = 0.00242000,
                            "PM10" = 0.00859040,
                            "PM2.5" = 0.00728000,
                            "SO2" = 0.00098000,
                            "VOC" = 0.01734200),
              
              "smoldering"= c("CH4" = 0.00986800,
                              "CO" = 0.21012000,
                              "CO2" = 1.39308000,
                              "NH3" = 0.00341056,
                              "NOx" = 0.00090800,
                              "PM10" = 0.01962576,
                              "PM2.5" = 0.01663200,
                              "SO2" = 0.00098000,
                              "VOC" = 0.04902680),
              
              "residual"= c("CH4" = 0.00986800,
                            "CO" = 0.21012000,
                            "CO2" = 1.39308000,
                            "NH3" = 0.00341056,
                            "NOx" = 0.00090800,
                            "PM10" = 0.01962576,
                            "PM2.5" = 0.01663200,
                            "SO2" = 0.00098000,
                            "VOC" = 0.04902680))

# portions consumption by consumption stage for small fuels
# tot: total fuel loading
# csd: % consumed
csdist <- function(tot, csd){
        csd_out <- list("flaming" = (tot * csd[1]), 
                        "smoldering" = (tot * csd[2]),
                        "residual" = (tot * csd[3]),
                        "total" = (tot * sum(csd)))
        
        return(csd_out)
}

# Activity fuels equations

# 100 hour woody fuels consumption
# Consume assumes a default 100-hr load of 4.8 tons/acre. In the consume
# documentation, this is listed as eq. A. However, it is only used once in 
# Eq. B, so I hard-coded it into Eq. B here.
# wind: windspeed, miles/hour
# slope: average slope, %
# fm_10hr: 10 hour fuel moisture, %
# hun_hr_sound: 100 hour fuel load
pct_hun_hr_calc <- function(wind, slope, fm_10hr, hun_hr_sound) {
        # Eq. B: Heat flux correction
        hfc <- (hun_hr_sound/4.8) * (1 + ((slope-20)/60) + (wind/4))
        
        # Eq. C: 10-hr fuel moisture correction
        fm_10hrc <- ifelse(hfc == 0, 0, 3 * ((log(hfc))/log(2)))
        
        #Eq. D: Adjusted 10-hr fuel moisture content
        fm_10hradj <- fm_10hr - fm_10hrc
        
        # Eq. E: % consumption of 100-hr fuels
        # the documentation and python code are different for this one, but the 
        # code doesn't mention it
        pc_100hr <- ifelse(fm_10hradj < 26.7, 
                           0.9 - (fm_10hradj - 12) * 0.0535,
                           ifelse(fm_10hradj >= 26.7 & 
                                          fm_10hradj < 29.3,
                                  -169.08 - (fm_10hradj * 18.393) - 
                                          ((fm_10hradj^2) * 0.6646) + 
                                          ((fm_10hradj^3) * 0.00798), 
                                  0))
        
        # restrict range to 0-1
        pc_100hrclip <- ifelse(pc_100hr > 1, 1,
                               ifelse(pc_100hr < 0, 0, pc_100hr))
        
        return(pc_100hrclip)
}

# According to consume 4.2 script con_calc_activity.py, Eq. G is obsolete
# Here's the equation used in the source code to estimate 1000 hour fuel 
# moisture
final1000hr <- function(fm_1000hr, fm_type) {
        adj_fm_1000hr <- fm_1000hr * cdic$adj[[fm_type]]
        return(adj_fm_1000hr)
}

# Eq.'s H, I, & J. From consume source code: if fm_type is NFDRS, divide by 1.4 
# not in documentation.
spring_summer_adjustment <- function(pct_hun_hr, adjfm_1000hr, fm_type) {
        # make masks
        mask_spring <- (pct_hun_hr <= 0.75)
        mask_trans <- (pct_hun_hr > 0.75 & pct_hun_hr < 0.85)
        mask_summer <- (pct_hun_hr >= 0.85)
        
        spring_ff <- (pct_hun_hr - 0.75) / 0.1
        
        # create m & b masks
        calc_mb <- function(x, fm_type, mask_spring,
                            mask_summer, mask_trans, spring_ff){
                sprg <- cdic$spring[[fm_type]][x]
                sumr <- cdic$summer[[fm_type]][x]
                
                mb <- (mask_spring * sprg) + (mask_summer * sumr) +
                        (mask_trans * (sprg + (spring_ff * (sumr - sprg))))
                # note from consume 4.0, line 107: transitional equation NOT in 
                # documentation- retrieved from source code
                return(mb)
        }
        
        # the first arguments in the following equations are different from  
        # consume because r indexes at 1 instead of 0
        m <- calc_mb(1, fm_type, mask_spring, mask_summer, mask_trans, spring_ff)
        b <- calc_mb(2, fm_type, mask_spring, mask_summer, mask_trans, spring_ff)
        # 
        diam_reduction <- (adjfm_1000hr * m) + b 
        
        # from consume source: not in doc, to keep DRED from reaching 0:
        diam_reduction <- ifelse(diam_reduction < 0.5,
                                 (adjfm_1000hr / 
                                          cdic$adj[[fm_type]] * (-0.005)) + 0.731,
                                 diam_reduction)
        
        # Eq. K: High fuel moisture diameter reduction is not included here
        # because fuel moistures in CBIP are much lower
        
        return(diam_reduction)
}        

# adjust for high intensity. This assumes highest intensity, and avoids needing 
# to estimate ignition time or fire size
high_intensity_adjustment <- function(diam_reduction, DRR){
        dr <- diam_reduction * DRR
        return(dr)
}

# calculate diameter reduction for woody fuels
diam_redux_calc <- function(pct_hun_hr, fm_1000hr, fm_type, DRR){
        
        adjfm_1000hr <- final1000hr(fm_1000hr, 
                                    fm_type)
        
        diam_reduction_seas <- spring_summer_adjustment(pct_hun_hr, 
                                                        adjfm_1000hr,
                                                        fm_type)
        
        diam_reduction_h_adj <- high_intensity_adjustment(diam_reduction_seas,
                                                          DRR)
        
        dred <- list("diam_reduction" = diam_reduction_h_adj,
                      "adjfm_1000hr" = adjfm_1000hr)
        return(dred)
}

# duff reduction equations
# days_since_rain: the # of days since at least 0.25 inches fell
duff_redux_activity <- function(diam_reduction, 
                                oneK_fsrt, 
                                tenK_fsrt, 
                                tnkp_fsrt, 
                                days_since_rain,
                                duff_upper_depth, 
                                duff_lower_depth){
        
        # Eq. R: Y-intercept adjustment 
        YADJ <- pmin((diam_reduction / 1.68), 1.0)
        
        # Eq. S: Drying period equations
        duff_depth <- duff_upper_depth + duff_lower_depth
        days_to_moist <- 21.0 * ((duff_depth / 3.0)^1.18) 
        days_to_dry <- 57.0 * ((duff_depth / 3.0)^1.18) 
        
        # Eq. T, U, V: Wet, moist, & dry duff reduction
        wet_df_redux <- ((0.537 * YADJ) +
                                 (0.057 * (oneK_fsrt[["total"]] +
                                                   tenK_fsrt[["total"]] +
                                                   tnkp_fsrt[["total"]])))
        
        moist_df_redux <- (0.323 * YADJ) + (1.034 *
                                                    (diam_reduction^0.5))
        
        
        quotient <- ifelse(days_to_moist != 0, 
                           (days_since_rain / days_to_moist), 
                           0)
        
        adj_wet_duff_redux <- (wet_df_redux + 
                                       (moist_df_redux - wet_df_redux) * quotient)
        
        
        # adjusted wet duff, to smooth the transition
        dry_df_redux <- (moist_df_redux +
                                 ((days_since_rain - days_to_dry) / 27.0))
        
        # conditionals specifying whether to use wet, moist, or dry
        duff_reduction <- ifelse(days_since_rain < days_to_moist,
                                 adj_wet_duff_redux,
                                 ifelse(days_since_rain > days_to_dry, 
                                        dry_df_redux, moist_df_redux))
        
        # Eq. W: Shallow duff adjustment
        duff_reduction2 =ifelse(duff_depth < 0.5,
                                duff_reduction * 0.5,
                                duff_reduction * ((0.25 * duff_depth) + 0.375))
        
        duff_reduction <- ifelse(duff_depth > 2.5,
                                 duff_reduction,
                                 duff_reduction2)
        
        # from consume source: not in manual- but in source code
        duff_reduction <- pmin(duff_reduction, duff_depth)
        
        return(duff_reduction)
}

# Eq. N. Quadratic mean diameter reduction For 1000hr and 10khr fuels
qmd_redux_calc <- function(QMD, diam_reduction){
        qmd_redux <- (1.0 - ((QMD - diam_reduction) / QMD)^2.0)
        return(qmd_redux)
}

# from consume: flaming diameter reduction (inches, %) this is a fixed value,
# from Ottmar 1983
flaming_DRED_calc <- function(hun_hr_sound, diam_reduction){
        flam <- function(hun_hr_sound) {
                1.0 - exp(1)^(-(abs((((20.0 - hun_hr_sound) / 20.0) - 1.0) /
                                           0.2313)^2.260))
        }
        
        flam_por <- flam(hun_hr_sound)
        flam_DRED <- flam_por * diam_reduction
        fld <- list("flam_DRED" = flam_DRED, "flamg_portion" = flam_por)
        return(fld)
}

# from consume: calculates flaming portion of large woody fuels and ensure that
# flaming portion is not greater than total
flamg_portion <- function(q, tlc, tld, fDRED){
        pct <- (1.0 - (((q - fDRED)^2) / (q^2)))
        f <- tld * pct
        fp <- ifelse(f > tlc, tlc, f)
        return(fp)
}
 
# distribute woody fuel consumption by combustion stage
# f = flaming consumption
# tots = total consumption (sound & rotten)
# rF = residual fractions (sound & rotten)
csdist_act <- function(f, tots, rF){
        dist <- list("flaming" = f,                            # flaming
                     "smoldering" = (tots - f) * (1.0 - rF),       # smoldering
                     "residual" = (tots - f) * rF,               # residual
                     "total" = tots)
        
        return(dist)
}

# 1-hr (0 to 1/4") woody fuels consumption
ccon_one_act <- function(one_hr_sound){
        csd <- c(1.0, 0.0, 0.0)
        onehr <- csdist(one_hr_sound, csd)
        return(onehr)
}

# 10-hr (1/4" to 1") woody fuels consumption
ccon_ten_act <- function(ten_hr_sound){
        csd <- c(1.0, 0.0, 0.0)
        tenhr <- csdist(ten_hr_sound, csd)
        return(tenhr)
}

# Eq. F: Total 100-hr (1" - 3") fuel consumption 
ccon_hun_act <- function(pct_hun_hr, diam_reduction, QMDS, hun_hr_sound){
        # browser()
        resFrac <- 0
        QMD_100hr <- 1.68
        total <- hun_hr_sound * pct_hun_hr
        flamgDRED <- flaming_DRED_calc(total, diam_reduction)
        
        # Flaming consumption 
        flamg <- ifelse(flamgDRED[[1]] >= QMD_100hr, total,
                        flamg_portion(QMDs[1], total,
                                      hun_hr_sound, flamgDRED[[1]])[1]) 
        # make sure flaming doesn't exceed total
        flamg <- ifelse(flamg > total, total, flamg)
        
        hundredhr <- csdist_act(flamg, total, resFrac)
        
        return(list("hundredhr" = hundredhr, 
                    "flamgDRED" = flamgDRED))
}

# Eq. O: 1000-hr (3" - 9") woody fuels consumption
# needs to be run on both sound and rotten
ccon_oneK_act <- function(fl_1000hr, QMDs, diam_reduction, flamgDRED, HS){
        
        resFrac <- ifelse(HS == "H",  0.25, 0.63) 
        
        oneK_redux <- qmd_redux_calc(QMDs[2], diam_reduction)
        
        total_redux <- oneK_redux * fl_1000hr
        
        flamg <- flamg_portion(QMDs[2], total_redux, fl_1000hr, flamgDRED)
        
        onekhr <- csdist_act(flamg, total_redux, resFrac)
        
        return(onekhr) 
}

# Eq. O, 10K-hr (9 to 20") woody fuels consumption. 
ccon_tenK_act <- function(fl_10khr, QMDs, diam_reduction, flamgDRED, HS){

        resFrac <- ifelse(HS == "H", 0.33, 0.67) 
        
        tenK_redux <- qmd_redux_calc(QMDs[3], diam_reduction)
        
        total_redux <- tenK_redux * fl_10khr
        
        flamg <- flamg_portion(QMDs[3], total_redux, fl_10khr, flamgDRED)
        
        tenKhr <- csdist_act(flamg, total_redux, resFrac)
        
        return(tenKhr)
}

#  >10,000-hr (20"+) woody fuel consumption. from consume source: Documentation
# does not include the condition that where 1,000 hr FM < 31%, redux is always 
# 5% in these cases. See table P in doc
ccon_tnkp_act <- function(adjfm_1000hr, flaming_portion, fl_gt10khr, HS){

        resFrac <- ifelse(HS == "H", 0.5, 0.67)
        pct_redux <- ifelse(adjfm_1000hr < 31, 
                            0.05, 
                            ifelse(adjfm_1000hr >= 31 &
                                           adjfm_1000hr < 35,
                                   (35.0 - adjfm_1000hr) / 100.0, 
                                   0)) 
        
        total_redux <- pct_redux * fl_gt10khr
        
        # From consume source: DISCREPANCY b/t SOURCE and DOCUMENTATION here
        # corresponds to source code right now for testing-sake
        flamg <- fl_gt10khr * flaming_portion
        
        flamg_adj <- ifelse(flamg > total_redux, total_redux, flamg) 
        
        gtenKhr <- csdist_act(flamg_adj, total_redux, resFrac)
        return(gtenKhr)
}

# activity forest floor reduction equations
ccon_ffr_activity <- function(diam_reduction, 
                              oneK_fsrt, 
                              tenK_fsrt,
                              tnkp_fsrt, 
                              days_since_rain,
                              duff_upper_depth, 
                              duff_lower_depth,
                              litter_depth,
                              lichen_depth,
                              moss_depth) {
        duff_redux <- duff_redux_activity(diam_reduction,
                                          oneK_fsrt, 
                                          tenK_fsrt,
                                          tnkp_fsrt, 
                                          days_since_rain,
                                          duff_upper_depth, 
                                          duff_lower_depth)
        
        duff_depth <- duff_upper_depth + duff_lower_depth
        
        ffr_total_depth <- duff_depth + litter_depth + lichen_depth + moss_depth
        
        quotient <- ifelse(duff_depth != 0, (duff_redux / duff_depth), 0.0)
        
        calculated_reduction <- ifelse(duff_depth > 0,
                                       quotient * ffr_total_depth, 0)
        ffr_redux <- ifelse(ffr_total_depth < calculated_reduction, 
                            ffr_total_depth, calculated_reduction)
        return(ffr_redux)
}

# compare forest floor reduction to litter layer depth
calc_and_reduce_ff <- function(layer_depth, ff_reduction){
        # if the depth of the layer is less than the available reduction
        #  use the depth of the layer. Otherwise, use the available reduction
        layer_reduction <- ifelse(layer_depth < ff_reduction, layer_depth, ff_reduction)
        # reduce the available reduction by the calculated amount
        ff_reduction <- ff_reduction - layer_reduction
        # should never be less than zero
        if(any(ff_reduction < 0) | any(is.na(ff_reduction))) stop("Error: Negative or NaN ff reduction found in calc_and_reduce_ff()")
        return(layer_reduction)
}

# litter consumption
ccon_forest_floor <- function(layer_depth, layer_loading, ff_reduction, csd){
        # get litter layer reduction
        layer_reduction <- calc_and_reduce_ff(layer_depth, ff_reduction)
        
        #how much was it reduced relative to the layer depth
        proportional_reduction <- ifelse(layer_depth > 0.0,
                                         layer_reduction / layer_depth, 0.0)
        
        total <- proportional_reduction * layer_loading
        
        return(csdist(total, csd))
}

# emissions calculations
emiss_calc <- function(cons, ef){
        return(data.frame(flaming = cons$flaming * ef$flaming,
                          smoldering = cons$smoldering * ef$smoldering,
                          residual = cons$residual * ef$residual))
}

# function to calculate pile consumption, assumes 90% consumption weighted 
# 70:15:15 between combustion phases
ccon_piled <- function(pile_load) {
        return(list("flaming" = (pile_load * 0.9) * 0.7,                           
                    "smoldering" = (pile_load * 0.9) * 0.15,      
                    "residual" = (pile_load * 0.9) * 0.15)) 
}

# combine all functions together to get consumption in tons/acre for each load
# catagory
ccon_activity <- function(fm1000,
                          fm_type, 
                          wind, 
                          slope, 
                          fm10, 
                          days_since_rain,
                          DRR,
                          LD){
        
        # specify fuel load
        one_hr_sound <- LD[["one_hr_sound"]]
        ten_hr_sound <- LD[["ten_hr_sound"]] 
        hun_hr_sound <- LD[["hun_hr_sound"]] 
        oneK_hr_sound <- LD[["oneK_hr_sound"]]
        oneK_hr_rotten <- LD[["oneK_hr_rotten"]]
        tenK_hr_sound <- LD[["tenK_hr_sound"]]
        tenK_hr_rotten <- LD[["tenK_hr_rotten"]]
        tnkp_hr_sound <- LD[["tnkp_hr_sound"]]
        tnkp_hr_rotten <- LD[["tnkp_hr_rotten"]]
        duff_upper_depth <- LD[["duff_upper_depth"]] 
        duff_upper_loading <- LD[["duff_upper_loading"]] 
        duff_lower_depth <- LD[["duff_lower_depth"]]
        litter_depth <- LD[["litter_depth"]]
        litter_loading <- LD[["litter_loading"]] 
        lichen_depth <- LD[["lichen_depth"]]
        moss_depth <- LD[["moss_depth"]]
        pile_landing <- LD[["pile_landing"]]
        pile_field <- LD[["pile_field"]]
        
        # run consumption functions for all size classes
        pct_hun_hr <- pct_hun_hr_calc(wind, slope, fm10, hun_hr_sound)
        
        # diameter reduction
        dred <- diam_redux_calc(pct_hun_hr, fm1000, fm_type, DRR)
        
        # 100 hr consumption
        hun_hr_fsrt <- ccon_hun_act(pct_hun_hr, dred$diam_reduction, QMDs, hun_hr_sound)
        
        # 1 hr consumption
        one_fsrt <- ccon_one_act(one_hr_sound)
        
        # 10 hr consumption
        ten_fsrt <- ccon_ten_act(ten_hr_sound)
        
        # 1,000 hr consumption
        oneK_fsrt_snd <- ccon_oneK_act(oneK_hr_sound, 
                                       QMDs,
                                       dred$diam_reduction, 
                                       hun_hr_fsrt$flamgDRED$flam_DRED,
                                       HS = "H")
        
        oneK_fsrt_rot <- ccon_oneK_act(oneK_hr_rotten, 
                                       QMDs,
                                       dred$diam_reduction, 
                                       hun_hr_fsrt$flamgDRED$flam_DRED,
                                       HS = "S")
        
        # 10,000 hr consumption
        tenK_fsrt_snd <- ccon_tenK_act(tenK_hr_sound, 
                                       QMDs,
                                       dred$diam_reduction, 
                                       hun_hr_fsrt$flamgDRED$flam_DRED,
                                       HS = "H")
        
        tenK_fsrt_rot <- ccon_tenK_act(tenK_hr_rotten, 
                                       QMDs,
                                       dred$diam_reduction, 
                                       hun_hr_fsrt$flamgDRED$flam_DRED,
                                       HS = "S")
        
        # consumption >10,000 hrs
        tnkp_fsrt_snd <- ccon_tnkp_act(dred$adjfm_1000hr,
                                       hun_hr_fsrt$flamgDRED$flamg_portion,
                                       tnkp_hr_sound,
                                       HS = "H")
        
        tnkp_fsrt_rot <- ccon_tnkp_act(dred$adjfm_1000hr,
                                       hun_hr_fsrt$flamgDRED$flamg_portion,
                                       tnkp_hr_rotten,
                                       HS = "S")
        # forest floor reduction
        ffr <- ccon_ffr_activity(dred$diam_reduction,
                                 oneK_fsrt_snd, 
                                 tenK_fsrt_snd, 
                                 tnkp_fsrt_snd, 
                                 days_since_rain,
                                 duff_upper_depth, 
                                 duff_lower_depth,
                                 litter_depth,
                                 lichen_depth,
                                 moss_depth)
        
        # litter consumption
        lit_fsrt <- ccon_forest_floor(litter_depth, 
                                      litter_loading, 
                                      ffr, 
                                      c(0.90, 0.10, 0.0))
        
        # upper duff consumption
        duff_fsrt <- ccon_forest_floor(duff_upper_depth, 
                                       duff_upper_loading, 
                                       ffr, 
                                       c(0.10, 0.70, 0.20))
        
        # pile consumption
        pile_field_fsrt <- ccon_piled(pile_field)
        pile_landing_fsrt <- ccon_piled(pile_landing)
        
        # create list of consumption values by emissions phase and size class
        cc_allclass <- data.frame("flaming" = (one_fsrt$flaming +
                                                       ten_fsrt$flaming + 
                                                       hun_hr_fsrt$hundredhr$flaming +
                                                       oneK_fsrt_snd$flaming + 
                                                       oneK_fsrt_rot$flaming +
                                                       tenK_fsrt_snd$flaming +
                                                       tenK_fsrt_rot$flaming +
                                                       tnkp_fsrt_snd$flaming +
                                                       tnkp_fsrt_rot$flaming +
                                                       lit_fsrt$flaming +
                                                       duff_fsrt$flaming +
                                                       pile_field_fsrt$flaming +
                                                       pile_landing_fsrt$flaming),
                                  "smoldering" = (one_fsrt$smoldering +
                                                          ten_fsrt$smoldering + 
                                                          hun_hr_fsrt$hundredhr$smoldering +
                                                          oneK_fsrt_snd$smoldering + 
                                                          oneK_fsrt_rot$smoldering +
                                                          tenK_fsrt_snd$smoldering +
                                                          tenK_fsrt_rot$smoldering +
                                                          tnkp_fsrt_snd$smoldering +
                                                          tnkp_fsrt_rot$smoldering +
                                                          lit_fsrt$smoldering +
                                                          duff_fsrt$smoldering +
                                                          pile_field_fsrt$smoldering +
                                                          pile_landing_fsrt$smoldering),
                                  "residual" = (one_fsrt$residual +
                                                        ten_fsrt$residual + 
                                                        hun_hr_fsrt$hundredhr$residual +
                                                        oneK_fsrt_snd$residual + 
                                                        oneK_fsrt_rot$residual +
                                                        tenK_fsrt_snd$residual +
                                                        tenK_fsrt_rot$residual +
                                                        tnkp_fsrt_snd$residual +
                                                        tnkp_fsrt_rot$residual +
                                                        lit_fsrt$residual +
                                                        duff_fsrt$residual +
                                                        pile_field_fsrt$residual +
                                                        pile_landing_fsrt$residual))

# create a data frame of emissions including spp and total
        em_dat <- emiss_calc(cc_allclass, ef_db)
        
        em_dat$total <- rowSums(em_dat)
        
        em_dat$e_spp <- rownames(em_dat)
        
        return(em_dat)
}

ccon_activity_piled_only <- function(LD){

        # specify fuel load
        pile_landing <- LD[["pile_landing"]]
        pile_field <- LD[["pile_field"]]
        
        # pile consumption
        pile_field_fsrt <- ccon_piled(pile_field)
        pile_landing_fsrt <- ccon_piled(pile_landing)
        
        # create list of consumption values by emissions phase and size class
        cc_allclass <- data.frame("flaming" = (pile_field_fsrt$flaming + pile_landing_fsrt$flaming),
                                  "smoldering" = (pile_field_fsrt$smoldering + pile_landing_fsrt$smoldering),
                                  "residual" = (pile_field_fsrt$residual + pile_landing_fsrt$residual))
        
        # create a data frame of emissions including spp and total
        em_dat <- emiss_calc(cc_allclass, ef_db)
        
        em_dat$total <- rowSums(em_dat)
        
        em_dat$e_spp <- rownames(em_dat)
        
        return(em_dat)
}
