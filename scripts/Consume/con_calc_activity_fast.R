################################################################################
# This script is an R translation of the woody fuels activity equations from
# consume 4.2, which is distributed within fuel fire tools. This script 
# leverages the data.table package to quickly run consume on a large data set. 
# This translation was performed as part of the California Biopower Impact
# Project for the CARBCAT model. The code was modified to better match the goals
# and geographic constraints of the project. 
#
# Tanslators: Micah Wright amd Andrew Harris, Humboldt State University
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


ccon_activity_fast <- function(dt, fm_type, days_since_rain, DRR){
        
        # combine all functions together to get consumption in tons/acre for each load
        # catagory
        ###################################################
        # run consumption functions for all size classes
        # #FORMERLY pct_hun_hr()
        ###################################################
        # Eq. B: Heat flux correction
        dt[, hfc := (hun_hr_sound / 4.8) * (1 + ((Slope - 20) / 60) + (Wind_corrected / 4))]
        # Eq. C: 10-hr fuel moisture correction
        dt[, fm_10hrc := hfc]
        dt[hfc != 0, fm_10hrc := 3 * ((log(hfc))/log(2))]
        #Eq. D: Adjusted 10-hr fuel moisture content
        dt[,fm_10hradj := Fm10 - fm_10hrc]
        # Eq. E: % consumption of 100-hr fuels
        # the documentation and python code are different for this one, but the 
        # code doesn't mention it
        dt[, pct_hun_hr := -169.08 - (fm_10hradj * 18.393) - ((fm_10hradj^2) * 0.6646) + ((fm_10hradj^3) * 0.00798)]
        dt[fm_10hradj < 26.7, pct_hun_hr := 0.9 - (fm_10hradj - 12) * 0.0535]
        dt[fm_10hradj >= 29.3, pct_hun_hr := 0]
        # restrict pct_hun_hr range to 0-1
        dt[pct_hun_hr > 1, pct_hun_hr := 1]
        dt[pct_hun_hr < 0, pct_hun_hr := 0]
        
        ######
        # We can possibly delete hfc, fm_10hrc, fm_10hradj if memory is an issue
        ######
        ###################################################
        # calculate diameter reduction for woody fuels
        # #FORMERLY diam_redux_calc()
        ###################################################
        # calculate diameter reduction for woody fuels
        dt[, adjfm_1000hr := Fm1000 * cdic$adj[[fm_type]]]
        # make masks
        dt[, ':=' (mask_spring = pct_hun_hr <= 0.75, 
                   mask_trans = pct_hun_hr > 0.75 & pct_hun_hr < 0.85, 
                   mask_summer = pct_hun_hr >= 0.85, 
                   spring_ff = (pct_hun_hr - 0.75) / 0.1)]
        # the first arguments in the following equations are different from  
        # consume because r indexes at 1 instead of 0
        dt[, ':=' (m = (mask_spring * cdic$spring[[fm_type]][1]) + (mask_summer * cdic$summer[[fm_type]][1]) + (mask_trans * (cdic$spring[[fm_type]][1] + (spring_ff * (cdic$summer[[fm_type]][1] - cdic$spring[[fm_type]][1])))),
                   b = (mask_spring * cdic$spring[[fm_type]][2]) + (mask_summer * cdic$summer[[fm_type]][2]) + (mask_trans * (cdic$spring[[fm_type]][2] + (spring_ff * (cdic$summer[[fm_type]][2] - cdic$spring[[fm_type]][2])))))]
        dt[, diam_reduction_seas := (adjfm_1000hr * m) + b ]
        # from consume source: not in doc, to keep DRED from reaching 0:
        dt[diam_reduction_seas < 0.5, diam_reduction_seas := (adjfm_1000hr / cdic$adj[[fm_type]] * (-0.005)) + 0.731]
        # Eq. K: High fuel moisture diameter reduction is not included here
        # because fuel moistures in CBIP are much lower
        dt[, diam_reduction := diam_reduction_seas * DRR]
        ######
        # We need adjfm_1000hr and diam_reduction; we can probably delete mask_spring, mask_summer, mask_trans, diam_reduction_seas
        ######
        ###################################################
        # 100 hr consumption
        # #FORMERLY ccon_hun_act()
        ###################################################
        # Eq. F: Total 100-hr (1" - 3") fuel consumption 
        resFrac <- 0
        QMD_100hr <- 1.68
        dt[, total_100 := hun_hr_sound * pct_hun_hr]
        # from consume: flaming diameter reduction (inches, %) this is a fixed value,
        # from Ottmar 1983
        dt[, flamg_portion := 1.0 - exp(1)^(-(abs((((20.0 - total_100) / 20.0) - 1.0) / 0.2313)^2.260))]
        dt[, flam_DRED := flamg_portion * diam_reduction]
        # Flaming consumption 
        dt[, flamg_100 := total_100] 
        dt[flam_DRED < QMD_100hr, flamg_100 := hun_hr_sound * (1.0 - (((QMDs[1] - flam_DRED)^2) / (QMDs[1]^2)))] 
        # Flamg cannot exceed the total.
        dt[flamg_100 > total_100, flamg_100 := total_100]
        # Add smoldering and residual values
        dt[, smoldg_100 := (total_100 - flamg_100) * (1.0 - resFrac)]
        dt[, resid_100 := (total_100 - flamg_100) * resFrac]
        ###################################################
        # 1 hr consumption
        # #FORMERLY ccon_one_act()
        ###################################################
        csd <- c(1.0, 0.0, 0.0)
        dt[,':=' (flamg_1 = (one_hr_sound * csd[1]), 
                  smoldg_1 = (one_hr_sound * csd[2]) ,
                  resid_1 = (one_hr_sound * csd[3]), 
                  total_1 = (one_hr_sound * sum(csd)))]
        
        ###################################################
        # 10 hr consumption
        # #FORMERLY ccon_ten_act()
        ###################################################
        # csd hasn't changed
        dt[, ':=' (flamg_10 = (ten_hr_sound * csd[1]), 
                   smoldg_10 = (ten_hr_sound * csd[2]),
                   resid_10 = (ten_hr_sound * csd[3]),
                   total_10 = (ten_hr_sound * sum(csd)))]
        
        ###################################################
        # 1,000 hr consumption
        # #FORMERLY ccon_oneK_act()
        # First is sound
        ###################################################
        HS <- "H"
        resFrac <- ifelse(HS == "H",  0.25, 0.63) 
        dt[, oneK_redux := (1.0 - ((QMDs[2] - diam_reduction) / QMDs[2])^2.0)]
        dt[, total_OneK_snd := oneK_redux * oneK_hr_sound] #MICAH TODO: Double check that this is the correct metric, might be daim redux
        dt[, flamg_OneK_snd := oneK_hr_sound * (1.0 - (((QMDs[2] - flam_DRED)^2) / (QMDs[2]^2)))]
        dt[flamg_OneK_snd > total_OneK_snd,flamg_OneK_snd := total_OneK_snd]
        dt[, ':=' (smoldg_OneK_snd = (total_OneK_snd - flamg_OneK_snd) * (1.0 - resFrac),
                   resid_OneK_snd = (total_OneK_snd - flamg_OneK_snd) * resFrac)]
        
        ###################################################
        # 1,000 hr consumption, continued
        # #FORMERLY ccon_oneK_act()
        # next is rotten
        ###################################################
        HS <- "S"
        resFrac <- ifelse(HS == "H",  0.25, 0.63) 
        dt[, oneK_redux := (1.0 - ((QMDs[2] - diam_reduction) / QMDs[2])^2.0)]
        dt[, total_OneK_rot := oneK_redux * oneK_hr_rotten]
        dt[, flamg_OneK_rot := oneK_hr_rotten * (1.0 - (((QMDs[2] - flam_DRED)^2) / (QMDs[2]^2)))]
        dt[flamg_OneK_rot > total_OneK_rot, flamg_OneK_rot := total_OneK_rot]
        dt[, ':=' (smoldg_OneK_rot = (total_OneK_rot - flamg_OneK_rot) * (1.0 - resFrac),
                   resid_OneK_rot = (total_OneK_rot - flamg_OneK_rot) * resFrac)]
        
        ###################################################
        # 10,000 hr consumption
        # #FORMERLY ccon_tenK_act()
        # First is sound
        ###################################################
        HS <- "H"
        resFrac <- ifelse(HS == "H", 0.33, 0.67)
        dt[, tenK_redux := (1.0 - ((QMDs[3] - diam_reduction) / QMDs[3])^2.0)]
        dt[, total_tenK_snd := tenK_redux * tenK_hr_sound]
        dt[, flamg_tenK_snd := tenK_hr_sound * (1.0 - (((QMDs[3] - flam_DRED)^2) / (QMDs[3]^2)))]
        dt[flamg_tenK_snd > total_tenK_snd, flamg_tenK_snd := total_tenK_snd]
        dt[, ':=' (smoldg_tenK_snd = (total_tenK_snd - flamg_tenK_snd) * (1.0 - resFrac),
                   resid_tenK_snd = (total_tenK_snd - flamg_tenK_snd) * resFrac)]
        
        ###################################################
        # 10,000 hr consumption
        # #FORMERLY ccon_tenK_act()
        # next is rotten
        ###################################################
        HS <- "S"
        resFrac <- ifelse(HS == "H", 0.33, 0.67)
        dt[, tenK_redux := (1.0 - ((QMDs[3] - diam_reduction) / QMDs[3])^2.0)]
        dt[, total_tenK_rot := tenK_redux * tenK_hr_rotten]
        dt[, flamg_tenK_rot := tenK_hr_rotten * (1.0 - (((QMDs[3] - flam_DRED)^2) / (QMDs[3]^2)))]
        dt[flamg_tenK_rot > total_tenK_rot, flamg_tenK_rot := total_tenK_rot]
        dt[, ':=' (smoldg_tenK_rot = (total_tenK_rot - flamg_tenK_rot) * (1.0 - resFrac),
                   resid_tenK_rot = (total_tenK_rot - flamg_tenK_rot) * resFrac)]
        
        ###################################################
        # 10,000+ hr consumption
        # #FORMERLY ccon_tnkp_act()
        # first is sound
        ###################################################
        HS <- "H"
        resFrac <- ifelse(HS == "H", 0.5, 0.67)
        dt[, pct_redux := (35.0 - adjfm_1000hr) / 100.0]
        dt[adjfm_1000hr < 31, pct_redux := 0.05]
        dt[adjfm_1000hr >= 35, pct_redux := 0]
        dt[, total_tnkp_snd := pct_redux * tnkp_hr_sound]
        # From consume source: DISCREPANCY b/t SOURCE and DOCUMENTATION here
        # corresponds to source code right now for testing-sake
        dt[, flamg_tnkp_snd := tnkp_hr_sound * flamg_portion]
        dt[flamg_tnkp_snd > total_tnkp_snd, flamg_tnkp_snd := total_tnkp_snd]
        dt[, ':=' (smoldg_tnkp_snd = (total_tnkp_snd - flamg_tnkp_snd) * (1.0 - resFrac),
                   resid_tnkp_snd = (total_tnkp_snd - flamg_tnkp_snd) * resFrac)]
        
        ###################################################
        # 10,000+ hr consumption
        # #FORMERLY ccon_tnkp_act()
        # second is rotten
        ###################################################
        HS <- "S"
        resFrac <- ifelse(HS == "H", 0.5, 0.67)
        dt[, pct_redux := (35.0 - adjfm_1000hr) / 100.0]
        dt[adjfm_1000hr < 31, pct_redux := 0.05]
        dt[adjfm_1000hr >=35, pct_redux := 0]
        dt[, total_tnkp_rot := pct_redux * tnkp_hr_rotten]
        # From consume source: DISCREPANCY b/t SOURCE and DOCUMENTATION here
        # corresponds to source code right now for testing-sake
        dt[, flamg_tnkp_rot := tnkp_hr_rotten * flamg_portion]
        dt[flamg_tnkp_rot > total_tnkp_rot, flamg_tnkp_rot := total_tnkp_rot]
        dt[, ':=' (smoldg_tnkp_rot = (total_tnkp_rot - flamg_tnkp_rot) * (1.0 - resFrac),
                   resid_tnkp_rot = (total_tnkp_rot - flamg_tnkp_rot) * resFrac)]
        
        ###################################################
        # forest floor reduction
        # #FORMERLY ccon_ffr_activity()
        ###################################################
        # Eq. R: Y-intercept adjustment 
        dt[, YADJ := pmin((diam_reduction / 1.68), 1.0)]
        # Eq. S: Drying period equations
        dt[, duff_depth := duff_upper_depth + duff_lower_depth]
        dt[, ':=' (days_to_moist = 21.0 * ((duff_depth / 3.0)^1.18), 
                   days_to_dry = 57.0 * ((duff_depth / 3.0)^1.18))]
        # Eq. T, U, V: Wet, moist, & dry duff reduction
        dt[, ':=' (wet_df_redux = ((0.537 * YADJ) + (0.057 * (total_OneK_snd + total_tenK_snd + total_tnkp_snd))),
                   moist_df_redux = (0.323 * YADJ) + (1.034 * (diam_reduction^0.5)))]
        dt[, moist_days_quotient := 0]
        dt[days_to_moist != 0, moist_days_quotient := days_since_rain / days_to_moist]
        dt[, adj_wet_duff_redux := (wet_df_redux + (moist_df_redux - wet_df_redux) * moist_days_quotient)]
        # adjusted wet duff, to smooth the transition
        dt[, dry_df_redux := (moist_df_redux + ((days_since_rain - days_to_dry) / 27.0))]
        # conditionals specifying whether to use wet, moist, or dry
        dt[, duff_reduction := adj_wet_duff_redux]
        dt[days_since_rain >= days_to_moist, duff_reduction := moist_df_redux]
        dt[days_since_rain >= days_to_moist & days_since_rain > days_to_dry, duff_reduction := dry_df_redux]
        # Eq. W: Shallow duff adjustment
        dt[, duff_reduction2 := duff_reduction * ((0.25 * duff_depth) + 0.375)]
        dt[duff_depth < 0.5, duff_reduction2 := duff_reduction * 0.5]
        dt[duff_depth <= 2.5, duff_reduction := duff_reduction2]
        # from consume source: not in manual- but in source code
        dt[, duff_reduction := pmin(duff_reduction, duff_depth)]
        # Back outside of duff_redux
        dt[, ffr_total_depth := duff_depth + litter_depth + lichen_depth + moss_depth]
        dt[, duff_quotient := (duff_reduction / duff_depth)]
        dt[duff_depth == 0, duff_quotient := 0]
        dt[, calculated_reduction := duff_quotient * ffr_total_depth]
        dt[duff_depth <= 0, calculated_reduction := 0]
        dt[, ffr := calculated_reduction]
        dt[ffr_total_depth < calculated_reduction, ffr := ffr_total_depth]
        
        ###################################################
        # forest floor reduction
        # #FORMERLY ccon_forest_floor()
        # First with litter
        ###################################################
        # if the depth of the layer is less than the available reduction
        #  use the depth of the layer. Otherwise, use the available reduction
        csd <- c(0.90, 0.10, 0.0)
        dt[, litter_reduction := ffr]
        dt[litter_depth < ffr, litter_reduction := litter_depth]
        dt[, ffr_errorflag := ffr - litter_reduction] # this should never be less than 0
        if(nrow(dt[(ffr_errorflag < 0) | is.na(ffr_errorflag), ]) > 0) stop("Error: Negative or NaN ff reduction found in calc_and_reduce_ff()")
        #how much was it reduced relative to the layer depth
        dt[, litter_proportional_reduction := litter_reduction / litter_depth]
        dt[litter_depth <= 0.0, litter_proportional_reduction := 0]
        dt[, total_litter := litter_proportional_reduction * litter_loading]
        dt[, flamg_litter := total_litter * csd[1]]
        dt[, smoldg_litter := total_litter * csd[2]]
        dt[, resid_litter := total_litter * csd[3]]
        
        ###################################################
        # forest floor reduction
        # #FORMERLY ccon_forest_floor()
        # Next with upper duff
        ###################################################
        csd = c(0.10, 0.70, 0.20)
        dt[, duff_reduction := ffr]
        dt[duff_upper_depth < ffr, duff_reduction := duff_upper_depth]
        dt[, ffr_errorflag := ffr - duff_reduction] # this should never be less than 0
        if(nrow(dt[(ffr_errorflag < 0) | is.na(ffr_errorflag), ]) > 0) stop("Error: Negative or NaN ff reduction found in calc_and_reduce_ff()")
        #how much was it reduced relative to the layer depth
        dt[, duff_proportional_reduction := duff_reduction / duff_upper_depth]
        
        dt[duff_upper_depth <= 0.0, duff_proportional_reduction := 0]
        dt[, total_duff := duff_proportional_reduction * duff_upper_loading]
        dt[, flamg_duff := total_duff * csd[1]]
        dt[, smoldg_duff := total_duff * csd[2]]
        dt[, resid_duff := total_duff * csd[3]]
        
        ###################################################
        # pile consumption
        # #FORMERLY ccon_piled()
        # First in field
        ###################################################
        dt[,':='(flamg_pile_field = (pile_field * 0.9) * 0.7,
                 smoldg_pile_field = (pile_field * 0.9) * 0.15,
                 resid_pile_field = (pile_field * 0.9) * 0.15)]
        
        ###################################################
        # pile consumption
        # #FORMERLY ccon_piled()
        # Next for landing piles
        ###################################################
        dt[,':='(flamg_pile_landing = (pile_landing * 0.9) * 0.7,
                 smoldg_pile_landing = (pile_landing * 0.9) * 0.15,
                 resid_pile_landing = (pile_landing * 0.9) * 0.15)]
        
        ###################################################
        # Calculate emissions
        # #FORMERLY emiss_calc()
        # we need to export a new data table with just the export data
        # TODO: possibly write a function for this?
        ###################################################
        dt[,':='(flaming = (flamg_1 + 
                                    flamg_10 + 
                                    flamg_100 + 
                                    flamg_OneK_snd +
                                    flamg_OneK_rot + 
                                    flamg_tenK_snd + 
                                    flamg_tenK_rot + 
                                    flamg_tnkp_snd + 
                                    flamg_tnkp_rot + 
                                    flamg_litter + 
                                    flamg_duff +
                                    flamg_pile_field + 
                                    flamg_pile_landing),
                 smoldering = (smoldg_1 + 
                                       smoldg_10 + 
                                       smoldg_100 + 
                                       smoldg_OneK_snd +
                                       smoldg_OneK_rot + 
                                       smoldg_tenK_snd + 
                                       smoldg_tenK_rot +
                                       smoldg_tnkp_snd + 
                                       smoldg_tnkp_rot + 
                                       smoldg_litter + 
                                       smoldg_duff + 
                                       smoldg_pile_field +
                                       smoldg_pile_landing),
                 residual = (resid_1 + 
                                     resid_10 + 
                                     resid_100 + 
                                     resid_OneK_snd +
                                     resid_OneK_rot + 
                                     resid_tenK_snd + 
                                     resid_tenK_rot + 
                                     resid_tnkp_snd +
                                     resid_tnkp_rot +
                                     resid_litter + 
                                     resid_duff + 
                                     resid_pile_field + 
                                     resid_pile_landing))]
        # Calculate total consumption
        dt[, ':='(total_unpiled_consumption = (flamg_1 + 
                                                   flamg_10 + 
                                                   flamg_100 + 
                                                   flamg_OneK_snd +
                                                   flamg_OneK_rot + 
                                                   flamg_tenK_snd + 
                                                   flamg_tenK_rot + 
                                                   flamg_tnkp_snd + 
                                                   flamg_tnkp_rot + 
                                                   smoldg_1 + 
                                                   smoldg_10 + 
                                                   smoldg_100 + 
                                                   smoldg_OneK_snd +
                                                   smoldg_OneK_rot + 
                                                   smoldg_tenK_snd + 
                                                   smoldg_tenK_rot +
                                                   smoldg_tnkp_snd + 
                                                   smoldg_tnkp_rot + 
                                                   resid_1 + 
                                                   resid_10 + 
                                                   resid_100 + 
                                                   resid_OneK_snd +
                                                   resid_OneK_rot + 
                                                   resid_tenK_snd + 
                                                   resid_tenK_rot + 
                                                   resid_tnkp_snd +
                                                   resid_tnkp_rot),
                  total_piled_consumption = (flamg_pile_field + 
                                                     flamg_pile_landing +
                                                     smoldg_pile_field +
                                                     smoldg_pile_landing +
                                                     resid_pile_field + 
                                                     resid_pile_landing))]
        
        # calculate char
        dt[, ':='(unpiled_char =  total_unpiled_consumption * ((11.30534 + -0.63064 * total_unpiled_consumption) / 100),
                  piled_char = total_piled_consumption * 0.01)]
        
        # trim to positive
        dt[unpiled_char < 0, unpiled_char := 0]
        
        # calculate total char
        dt[, total_char := unpiled_char + piled_char]
        
        dt[,':='(flaming_CH4 = flaming * ef_db$flaming[['CH4']],
                 flaming_CO = flaming * ef_db$flaming[['CO']], 
                 flaming_CO2 = flaming * ef_db$flaming[['CO2']],
                 flaming_NH3 = flaming * ef_db$flaming[['NH3']], 
                 flaming_NOx = flaming * ef_db$flaming[['NOx']], 
                 flaming_PM10 = flaming * ef_db$flaming[['PM10']], 
                 flaming_PM2.5 = flaming * ef_db$flaming[['PM2.5']], 
                 flaming_SO2 = flaming * ef_db$flaming[['SO2']], 
                 flaming_VOC = flaming * ef_db$flaming[['VOC']],
                 smoldering_CH4 = smoldering * ef_db$smoldering[['CH4']],
                 smoldering_CO = smoldering * ef_db$smoldering[['CO']], 
                 smoldering_CO2 = smoldering * ef_db$smoldering[['CO2']], 
                 smoldering_NH3 = smoldering * ef_db$smoldering[['NH3']], 
                 smoldering_NOx = smoldering * ef_db$smoldering[['NOx']], 
                 smoldering_PM10 = smoldering * ef_db$smoldering[['PM10']], 
                 smoldering_PM2.5 = smoldering * ef_db$smoldering[['PM2.5']], 
                 smoldering_SO2 = smoldering * ef_db$smoldering[['SO2']], 
                 smoldering_VOC = smoldering * ef_db$smoldering[['VOC']],
                 residual_CH4 = residual * ef_db$residual[['CH4']],
                 residual_CO = residual * ef_db$residual[['CO']], 
                 residual_CO2 = residual * ef_db$residual[['CO2']],
                 residual_NH3 = residual * ef_db$residual[['NH3']],
                 residual_NOx = residual * ef_db$residual[['NOx']], 
                 residual_PM10 = residual * ef_db$residual[['PM10']], 
                 residual_PM2.5 = residual * ef_db$residual[['PM2.5']], 
                 residual_SO2 = residual * ef_db$residual[['SO2']],
                 residual_VOC = residual * ef_db$residual[['VOC']])]
        
        dt[, ':=' (total_CH4 = (flaming_CH4 + smoldering_CH4 + residual_CH4), 
                   total_CO = (flaming_CO + smoldering_CO + residual_CO), 
                   total_CO2 = (flaming_CO2 + smoldering_CO2 + residual_CO2), 
                   total_NH3 = (flaming_NH3 + smoldering_NH3 + residual_NH3),
                   total_NOx = (flaming_NOx + smoldering_NOx + residual_NOx),
                   total_PM10 = (flaming_PM10 + smoldering_PM10 + residual_PM10),
                   total_PM2.5 = (flaming_PM2.5 + smoldering_PM2.5 + residual_PM2.5),
                   total_SO2 = (flaming_SO2 + smoldering_SO2 + residual_SO2),
                   total_VOC = (flaming_VOC + smoldering_VOC + residual_VOC))]
        
        out_dt <- dt[,list(x, 
                           y,
                           fuelbed_number, 
                           FCID2018, 
                           ID,
                           Silvicultural_Treatment, 
                           Harvest_Type,
                           Harvest_System,
                           Burn_Type,
                           Biomass_Collection,
                           Slope,
                           Fm10,
                           Fm1000,
                           Wind_corrected,
                           duff_upper_loading = duff_upper_loading - (flamg_duff + smoldg_duff + resid_duff),
                           litter_loading = litter_loading - (flamg_litter + smoldg_litter + resid_litter), 
                           one_hr_sound = one_hr_sound - (flamg_1 + smoldg_1 + resid_1), 
                           ten_hr_sound = ten_hr_sound - (flamg_10 + smoldg_10 + resid_10),
                           hun_hr_sound = hun_hr_sound - (flamg_100 + smoldg_100 + resid_100),
                           oneK_hr_sound = (oneK_hr_sound - (flamg_OneK_snd + smoldg_OneK_snd + resid_OneK_snd)) + (pile_field - (flamg_pile_field + smoldg_pile_field + resid_pile_field)) + (pile_landing - (flamg_pile_landing + smoldg_pile_landing + resid_pile_landing)),
                           oneK_hr_rotten = oneK_hr_rotten - (flamg_OneK_rot + smoldg_OneK_rot + resid_OneK_rot),
                           tenK_hr_sound = tenK_hr_sound - (flamg_tenK_snd + smoldg_tenK_snd + resid_tenK_snd), 
                           tenK_hr_rotten = tenK_hr_rotten - (flamg_tenK_rot + smoldg_tenK_rot + resid_tenK_rot),
                           tnkp_hr_sound = tnkp_hr_sound - (flamg_tnkp_snd + smoldg_tnkp_snd + resid_tnkp_snd),
                           tnkp_hr_rotten = tnkp_hr_rotten - (flamg_tnkp_rot + smoldg_tnkp_rot + resid_tnkp_rot),
                           pile_field = 0,
                           pile_landing = 0,
                           total_char, 
                           flaming_CH4,
                           flaming_CO,
                           flaming_CO2, 
                           flaming_NH3, 
                           flaming_NOx, 
                           flaming_PM10,
                           flaming_PM2.5, 
                           flaming_SO2, 
                           flaming_VOC, 
                           smoldering_CH4, 
                           smoldering_CO,
                           smoldering_CO2, 
                           smoldering_NH3, 
                           smoldering_NOx, 
                           smoldering_PM10, 
                           smoldering_PM2.5, 
                           smoldering_SO2, 
                           smoldering_VOC,
                           residual_CH4,
                           residual_CO, 
                           residual_CO2, 
                           residual_NH3,
                           residual_NOx, 
                           residual_PM10, 
                           residual_PM2.5, 
                           residual_SO2,
                           residual_VOC, 
                           total_CH4, 
                           total_CO, 
                           total_CO2,
                           total_NH3,
                           total_NOx, 
                           total_PM10, 
                           total_PM2.5,
                           total_SO2, 
                           total_VOC)]
        
        return(out_dt)

}

ccon_activity_piled_only_fast <- function(dt){
        ###################################################
        # pile consumption
        # #FORMERLY ccon_piled()
        # First in field
        ###################################################
        dt[, ':=' (flamg_pile_field = (pile_field * 0.9) * 0.7,
                   smoldg_pile_field = (pile_field * 0.9) * 0.15,
                   resid_pile_field = (pile_field * 0.9) * 0.15)]
        
        ###################################################
        # pile consumption
        # #FORMERLY ccon_piled()
        # Next for landing piles
        ###################################################
        dt[, ':=' (flamg_pile_landing = (pile_landing * 0.9) * 0.7,
                   smoldg_pile_landing = (pile_landing * 0.9) * 0.15,
                   resid_pile_landing = (pile_landing * 0.9) * 0.15)]
        
        
        dt[, ':=' (flaming = (flamg_pile_field + flamg_pile_landing),
                   smoldering = (smoldg_pile_field + smoldg_pile_landing),
                   residual = (resid_pile_field + resid_pile_landing))]
        
        dt[, ':='(total_piled_consumption = (flaming +
                                                 smoldering +
                                                 residual))]
        
        dt[, total_char := total_piled_consumption * 0.01]
        
        dt[, ':=' (flaming_CH4 = flaming * ef_db$flaming[['CH4']], 
                   flaming_CO = flaming * ef_db$flaming[['CO']], 
                   flaming_CO2 = flaming * ef_db$flaming[['CO2']], 
                   flaming_NH3 = flaming * ef_db$flaming[['NH3']], 
                   flaming_NOx = flaming * ef_db$flaming[['NOx']], 
                   flaming_PM10 = flaming * ef_db$flaming[['PM10']], 
                   flaming_PM2.5 = flaming * ef_db$flaming[['PM2.5']], 
                   flaming_SO2 = flaming * ef_db$flaming[['SO2']], 
                   flaming_VOC = flaming * ef_db$flaming[['VOC']],
                   smoldering_CH4 = smoldering * ef_db$smoldering[['CH4']], 
                   smoldering_CO = smoldering * ef_db$smoldering[['CO']], 
                   smoldering_CO2 = smoldering * ef_db$smoldering[['CO2']],
                   smoldering_NH3 = smoldering * ef_db$smoldering[['NH3']], 
                   smoldering_NOx = smoldering * ef_db$smoldering[['NOx']], 
                   smoldering_PM10 = smoldering * ef_db$smoldering[['PM10']], 
                   smoldering_PM2.5 = smoldering * ef_db$smoldering[['PM2.5']], 
                   smoldering_SO2 = smoldering * ef_db$smoldering[['SO2']], 
                   smoldering_VOC = smoldering * ef_db$smoldering[['VOC']],
                   residual_CH4 = residual * ef_db$residual[['CH4']],
                   residual_CO = residual * ef_db$residual[['CO']],
                   residual_CO2 = residual * ef_db$residual[['CO2']], 
                   residual_NH3 = residual * ef_db$residual[['NH3']],
                   residual_NOx = residual * ef_db$residual[['NOx']],
                   residual_PM10 = residual * ef_db$residual[['PM10']],
                   residual_PM2.5 = residual * ef_db$residual[['PM2.5']], 
                   residual_SO2 = residual * ef_db$residual[['SO2']],
                   residual_VOC = residual * ef_db$residual[['VOC']])]
        
        dt[, ':=' (total_CH4 = (flaming_CH4 + smoldering_CH4 + residual_CH4), 
                   total_CO = (flaming_CO + smoldering_CO + residual_CO), 
                   total_CO2 = (flaming_CO2 + smoldering_CO2 + residual_CO2), 
                   total_NH3 = (flaming_NH3 + smoldering_NH3 + residual_NH3),
                   total_NOx = (flaming_NOx + smoldering_NOx + residual_NOx),
                   total_PM10 = (flaming_PM10 + smoldering_PM10 + residual_PM10),
                   total_PM2.5 = (flaming_PM2.5 + smoldering_PM2.5 + residual_PM2.5),
                   total_SO2 = (flaming_SO2 + smoldering_SO2 + residual_SO2),
                   total_VOC = (flaming_VOC + smoldering_VOC + residual_VOC))]
        
        out_dt <- dt[,list(x, 
                           y,
                           fuelbed_number,
                           FCID2018, ID, 
                           Silvicultural_Treatment,
                           Harvest_Type,
                           Harvest_System,
                           Burn_Type,
                           Biomass_Collection, 
                           Slope,
                           Fm10,
                           Fm1000,
                           Wind_corrected,
                           duff_upper_loading = duff_upper_loading,
                           litter_loading = litter_loading, 
                           one_hr_sound = one_hr_sound, 
                           ten_hr_sound = ten_hr_sound,
                           hun_hr_sound = hun_hr_sound,
                           oneK_hr_sound = oneK_hr_sound + (pile_field - (flamg_pile_field + smoldg_pile_field + resid_pile_field)) + (pile_landing - (flamg_pile_landing + smoldg_pile_landing + resid_pile_landing)),
                           oneK_hr_rotten = oneK_hr_rotten,
                           tenK_hr_sound = tenK_hr_sound, 
                           tenK_hr_rotten = tenK_hr_rotten,
                           tnkp_hr_sound = tnkp_hr_sound,
                           tnkp_hr_rotten = tnkp_hr_rotten,
                           pile_field = 0,
                           pile_landing = 0,
                           total_char, 
                           flaming_CH4,
                           flaming_CO, 
                           flaming_CO2,
                           flaming_NH3,
                           flaming_NOx, 
                           flaming_PM10,
                           flaming_PM2.5, 
                           flaming_SO2,
                           flaming_VOC, 
                           smoldering_CH4, 
                           smoldering_CO, 
                           smoldering_CO2,
                           smoldering_NH3,
                           smoldering_NOx, 
                           smoldering_PM10, 
                           smoldering_PM2.5,
                           smoldering_SO2, 
                           smoldering_VOC,
                           residual_CH4, 
                           residual_CO, 
                           residual_CO2,
                           residual_NH3, 
                           residual_NOx, 
                           residual_PM10, 
                           residual_PM2.5, 
                           residual_SO2,
                           residual_VOC, 
                           total_CH4,
                           total_CO, 
                           total_CO2, 
                           total_NH3,
                           total_NOx,
                           total_PM10,
                           total_PM2.5, 
                           total_SO2, 
                           total_VOC)]
        
        return(out_dt)
}
        