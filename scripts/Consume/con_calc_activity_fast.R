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

# function to calculate char in unpiled fuels
# m_cons: material consumed
char_scat <- function(m_cons) {
        ifelse((m_cons * ((11.30534 + -0.63064 * m_cons) / 100)) < 0, 0, (m_cons * ((11.30534 + -0.63064 * m_cons) / 100)))
}

# char for piles
char_pile <- function(m_cons) {
        m_cons * 0.01
}

ccon_activity_fast <- function(dt, fm_type, days_since_rain, DRR){
        
        ###################################################
        # calculate % of 100-hr fuels consumed
        # pct_hun_hr()
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
        
         ###################################################
        # calculate diameter reduction for woody fuels
        # diam_redux_calc()
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
        ###################################################
        # 100 hr consumption
        # ccon_hun_act()
        ###################################################
        # Eq. F: Total 100-hr (1" - 3") fuel consumption 
        resFrac <- 0
        QMD_100hr <- 1.68
        dt[, total_100 := hun_hr_sound * pct_hun_hr]
        # char
        dt[, char_100 := char_scat(total_100)]
        dt[, total_100 := total_100 - char_100]
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
        # ccon_one_act()
        ###################################################
        csd <- c(1.0, 0.0, 0.0)
        dt[,':=' (flamg_1 = (one_hr_sound * csd[1]), 
                  smoldg_1 = (one_hr_sound * csd[2]) ,
                  resid_1 = (one_hr_sound * csd[3]), 
                  total_1 = (one_hr_sound * sum(csd)))]
        
        ###################################################
        # 10 hr consumption
        # ccon_ten_act()
        ###################################################
        # csd hasn't changed
        dt[, ':=' (flamg_10 = (ten_hr_sound * csd[1]), 
                   smoldg_10 = (ten_hr_sound * csd[2]),
                   resid_10 = (ten_hr_sound * csd[3]),
                   total_10 = (ten_hr_sound * sum(csd)))]
        
        ###################################################
        # 1,000 hr consumption
        # ccon_oneK_act()
        # First is sound
        ###################################################
        HS <- "H"
        resFrac <- ifelse(HS == "H",  0.25, 0.63) 
        dt[, oneK_redux := (1.0 - ((QMDs[2] - diam_reduction) / QMDs[2])^2.0)]
        dt[, total_OneK_snd := oneK_redux * oneK_hr_sound] 
        # char
        dt[, char_OneK_snd := char_scat(total_OneK_snd)]
        dt[, total_OneK_snd := total_OneK_snd - char_OneK_snd]
        dt[, flamg_OneK_snd := oneK_hr_sound * (1.0 - (((QMDs[2] - flam_DRED)^2) / (QMDs[2]^2)))]
        dt[flamg_OneK_snd > total_OneK_snd,flamg_OneK_snd := total_OneK_snd]
        dt[, ':=' (smoldg_OneK_snd = (total_OneK_snd - flamg_OneK_snd) * (1.0 - resFrac),
                   resid_OneK_snd = (total_OneK_snd - flamg_OneK_snd) * resFrac)]
        
        ###################################################
        # 1,000 hr consumption, continued
        # ccon_oneK_act()
        # next is rotten
        ###################################################
        HS <- "S"
        resFrac <- ifelse(HS == "H",  0.25, 0.63) 
        dt[, oneK_redux := (1.0 - ((QMDs[2] - diam_reduction) / QMDs[2])^2.0)]
        dt[, total_OneK_rot := oneK_redux * oneK_hr_rotten]
        # char
        dt[, char_OneK_rot := char_scat(total_OneK_rot)]
        dt[, total_OneK_rot := total_OneK_rot - char_OneK_rot]
        dt[, flamg_OneK_rot := oneK_hr_rotten * (1.0 - (((QMDs[2] - flam_DRED)^2) / (QMDs[2]^2)))]
        dt[flamg_OneK_rot > total_OneK_rot, flamg_OneK_rot := total_OneK_rot]
        dt[, ':=' (smoldg_OneK_rot = (total_OneK_rot - flamg_OneK_rot) * (1.0 - resFrac),
                   resid_OneK_rot = (total_OneK_rot - flamg_OneK_rot) * resFrac)]
        
        ###################################################
        # 10,000 hr consumption
        # ccon_tenK_act()
        # First is sound
        ###################################################
        HS <- "H"
        resFrac <- ifelse(HS == "H", 0.33, 0.67)
        dt[, tenK_redux := (1.0 - ((QMDs[3] - diam_reduction) / QMDs[3])^2.0)]
        dt[, total_tenK_snd := tenK_redux * tenK_hr_sound]
        # char
        dt[, char_tenK_snd := char_scat(total_tenK_snd)]
        dt[, total_tenK_snd := total_tenK_snd - char_tenK_snd]
        dt[, flamg_tenK_snd := tenK_hr_sound * (1.0 - (((QMDs[3] - flam_DRED)^2) / (QMDs[3]^2)))]
        dt[flamg_tenK_snd > total_tenK_snd, flamg_tenK_snd := total_tenK_snd]
        dt[, ':=' (smoldg_tenK_snd = (total_tenK_snd - flamg_tenK_snd) * (1.0 - resFrac),
                   resid_tenK_snd = (total_tenK_snd - flamg_tenK_snd) * resFrac)]
        
        ###################################################
        # 10,000 hr consumption
        # ccon_tenK_act()
        # next is rotten
        ###################################################
        HS <- "S"
        resFrac <- ifelse(HS == "H", 0.33, 0.67)
        dt[, tenK_redux := (1.0 - ((QMDs[3] - diam_reduction) / QMDs[3])^2.0)]
        dt[, total_tenK_rot := tenK_redux * tenK_hr_rotten]
        # char
        dt[, char_tenK_rot := char_scat(total_tenK_rot)]
        dt[, total_tenK_rot := total_tenK_rot - char_tenK_rot]
        dt[, flamg_tenK_rot := tenK_hr_rotten * (1.0 - (((QMDs[3] - flam_DRED)^2) / (QMDs[3]^2)))]
        dt[flamg_tenK_rot > total_tenK_rot, flamg_tenK_rot := total_tenK_rot]
        dt[, ':=' (smoldg_tenK_rot = (total_tenK_rot - flamg_tenK_rot) * (1.0 - resFrac),
                   resid_tenK_rot = (total_tenK_rot - flamg_tenK_rot) * resFrac)]
        
        ###################################################
        # 10,000+ hr consumption
        # ccon_tnkp_act()
        # first is sound
        ###################################################
        HS <- "H"
        resFrac <- ifelse(HS == "H", 0.5, 0.67)
        dt[, pct_redux := (35.0 - adjfm_1000hr) / 100.0]
        dt[adjfm_1000hr < 31, pct_redux := 0.05]
        dt[adjfm_1000hr >= 35, pct_redux := 0]
        dt[, total_tnkp_snd := pct_redux * tnkp_hr_sound]
        # char
        dt[, char_tnkp_snd := char_scat(total_tnkp_snd)]
        dt[, total_tnkp_snd := total_tnkp_snd - char_tnkp_snd]
        # From consume source: DISCREPANCY b/t SOURCE and DOCUMENTATION here
        # corresponds to source code right now for testing-sake
        dt[, flamg_tnkp_snd := tnkp_hr_sound * flamg_portion]
        dt[flamg_tnkp_snd > total_tnkp_snd, flamg_tnkp_snd := total_tnkp_snd]
        dt[, ':=' (smoldg_tnkp_snd = (total_tnkp_snd - flamg_tnkp_snd) * (1.0 - resFrac),
                   resid_tnkp_snd = (total_tnkp_snd - flamg_tnkp_snd) * resFrac)]
        
        ###################################################
        # 10,000+ hr consumption
        # ccon_tnkp_act()
        # second is rotten
        ###################################################
        HS <- "S"
        resFrac <- ifelse(HS == "H", 0.5, 0.67)
        dt[, pct_redux := (35.0 - adjfm_1000hr) / 100.0]
        dt[adjfm_1000hr < 31, pct_redux := 0.05]
        dt[adjfm_1000hr >=35, pct_redux := 0]
        dt[, total_tnkp_rot := pct_redux * tnkp_hr_rotten]
        # char
        dt[, char_tnkp_rot := char_scat(total_tnkp_rot)]
        dt[, total_tnkp_rot := total_tnkp_rot - char_tnkp_rot]
        # From consume source: DISCREPANCY b/t SOURCE and DOCUMENTATION here
        # corresponds to source code right now for testing-sake
        dt[, flamg_tnkp_rot := tnkp_hr_rotten * flamg_portion]
        dt[flamg_tnkp_rot > total_tnkp_rot, flamg_tnkp_rot := total_tnkp_rot]
        dt[, ':=' (smoldg_tnkp_rot = (total_tnkp_rot - flamg_tnkp_rot) * (1.0 - resFrac),
                   resid_tnkp_rot = (total_tnkp_rot - flamg_tnkp_rot) * resFrac)]
        
        ###################################################
        # forest floor reduction
        # ccon_ffr_activity()
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
        # ccon_forest_floor()
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
        # ccon_forest_floor()
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
        # ccon_piled()
        # this is combined for wildfire scenarios
        ###################################################
        dt[,':='(flamg_pile = ((pile_field * 0.9) * 0.7) + ((pile_landing * 0.9) * 0.7),
                 smoldg_pile = ((pile_field * 0.9) * 0.15) + ((pile_landing * 0.9) * 0.15),
                 resid_pile = ((pile_field * 0.9) * 0.15) + ((pile_landing * 0.9) * 0.15))]
        
        # calculate pile char and update consumed mass
        dt[, ':=' (pile_char := char_pile((flamg_pile + smoldg_pile + resid_pile)),
                   flamg_pile = flamg_pile - char_pile(flamg_pile), 
                   smoldg_pile = smoldg_pile -  char_pile(smoldg_pile),
                   resid_pile = resid_pile - char_pile(resid_pile))]
        
        # aggregate the data as much as possible to get residue only and total by combustion phase
        # first aggregate the total consumed by combustion phase
        c_phase <- c("flamg", "smoldg", "resid")
        size <- c("duff", "litter", "1", "10", "100", paste(rep(c("OneK", "tenK", "tnkp"), each = 2), c("snd", "rot"), sep = "_"))

        # loop though each combustion phase and get the total consumption
        for (col in c_phase) {
                dt[ , paste("total", (col), sep = "_") := rowSums(.SD), .SDcols = paste((col), size, sep = "_")]
        }
        
        # calculate total char
        # update size to only include sizes with char
        size <- c("100", paste(rep(c("OneK", "tenK", "tnkp"), each = 2), c("snd", "rot"), sep = "_"))
        dt[ ,total_char := rowSums(.SD), .SDcols = paste("char", size, sep = "_")]
        
        # now aggregate consumed data, but only consider actual residues
        # this assumes that the proportion of the fuel that was residue is 
        # the same as the proportion of the consumed fuel that was residue
        dt[, ':=' (flamg_duff_residue = flamg_duff * duff_upper_load_pr,
                   smoldg_duff_residue = smoldg_duff * duff_upper_load_pr,
                   resid_duff_residue = resid_duff * duff_upper_load_pr,
                   flamg_foliage_residue = flamg_litter * litter_loading_pr,
                   smoldg_foliage_residue = smoldg_litter * litter_loading_pr,
                   resid_foliage_residue = resid_litter * litter_loading_pr,
                   flamg_fwd_residue = ((flamg_1 * one_hr_sound_pr) +
                                                (flamg_10 * ten_hr_sound_pr) +
                                                (flamg_100 * hun_hr_sound_pr)),
                   flamg_cwd_residue = ((flamg_OneK_snd * oneK_hr_sound_pr) +
                                                (flamg_OneK_rot * oneK_hr_rotten_pr) +
                                                (flamg_tenK_snd * tenK_hr_sound_pr) +
                                                (flamg_tenK_rot * tenK_hr_rotten_pr) +
                                                (flamg_tnkp_snd * tnkp_hr_sound_pr) +
                                                (flamg_tnkp_rot * tnkp_hr_rotten_pr)),
                   smoldg_fwd_residue = ((smoldg_1 * one_hr_sound_pr) +
                                                (smoldg_10 * ten_hr_sound_pr) +
                                                (smoldg_100 * hun_hr_sound_pr)),
                   smoldg_cwd_residue = ((smoldg_OneK_snd * oneK_hr_sound_pr) +
                                                (smoldg_OneK_rot * oneK_hr_rotten_pr) +
                                                (smoldg_tenK_snd * tenK_hr_sound_pr) +
                                                (smoldg_tenK_rot * tenK_hr_rotten_pr) +
                                                (smoldg_tnkp_snd * tnkp_hr_sound_pr) +
                                                (smoldg_tnkp_rot * tnkp_hr_rotten_pr)),
                   resid_fwd_residue = ((resid_1 * one_hr_sound_pr) +
                                                 (resid_10 * ten_hr_sound_pr) +
                                                 (resid_100 * hun_hr_sound_pr)),
                   resid_cwd_residue = ((resid_OneK_snd * oneK_hr_sound_pr) +
                                                 (resid_OneK_rot * oneK_hr_rotten_pr) +
                                                 (resid_tenK_snd * tenK_hr_sound_pr) +
                                                 (resid_tenK_rot * tenK_hr_rotten_pr) +
                                                 (resid_tnkp_snd * tnkp_hr_sound_pr) +
                                                 (resid_tnkp_rot * tnkp_hr_rotten_pr)),
                   char_fwd_residue = char_100 * hun_hr_sound_pr,
                   char_cwd_residue = ((char_OneK_snd * oneK_hr_sound_pr) +
                                                (char_OneK_rot * oneK_hr_rotten_pr) +
                                                (char_tenK_snd * tenK_hr_sound_pr) +
                                                (char_tenK_rot * tenK_hr_rotten_pr) +
                                                (char_tnkp_snd * tnkp_hr_sound_pr) +
                                                (char_tnkp_rot * tnkp_hr_rotten_pr)))]
        
        # remove all the unnecessary columns
        dt[, c("hfc",
               "fm_10hrc",
               "fm_10hradj",
               "pct_hun_hr",
               "adjfm_1000hr",
               "mask_spring",
               "mask_trans",
               "mask_summer",
               "spring_ff",
               "m",
               "b" ,
               "diam_reduction_seas",
               "diam_reduction",
               "flamg_portion",
               "flam_DRED",
               "YADJ", 
               "duff_depth",
               "days_to_moist",
               "days_to_dry",
               "pct_redux",
               "oneK_redux",
               "tenK_redux",
               "wet_df_redux",
               "moist_df_redux",
               "moist_days_quotient",
               "adj_wet_duff_redux",
               "dry_df_redux",
               "duff_reduction",
               "duff_reduction2",
               "ffr_total_depth",
               "duff_quotient",
               "calculated_reduction",
               "ffr",
               "litter_reduction",
               "ffr_errorflag",
               "litter_proportional_reduction",
               "duff_proportional_reduction") := NULL]

}

ccon_activity_piled_only_fast <- function(dt, burn_type) {
        
        if(burn_type == "Pile") {
                
                dt[, ':=' (flamg_pile = (pile_landing * 0.9) * 0.7,
                           smoldg_pile = (pile_landing * 0.9) * 0.15,
                           resid_pile = (pile_landing * 0.9) * 0.15)]
                
        } 
        
        if(burn_type == "Jackpot") { 
                
                dt[,':='(flamg_pile = ((pile_field * 0.9) * 0.7) + ((pile_landing * 0.9) * 0.7),
                         smoldg_pile = ((pile_field * 0.9) * 0.15) + ((pile_landing * 0.9) * 0.15),
                         resid_pile = ((pile_field * 0.9) * 0.15) + ((pile_landing * 0.9) * 0.15))]
        }
        
        # calculate char and update consumed mass
        dt[, ':=' (pile_char := char_pile((flamg_pile + smoldg_pile + resid_pile)),
                   flamg_pile = flamg_pile - char_pile(flamg_pile), 
                   smoldg_pile = smoldg_pile -  char_pile(smoldg_pile),
                   resid_pile = resid_pile - char_pile(resid_pile))]
        
        # assign 0 values to other burn cols for eval in  calc_emissions
        c_phase <- c("flamg", "smoldg", "resid")
        size <- c("duff_residue", "foliage_residue", "fwd_residue", "cwd_residue", "duff", "litter", "1", "10", "100", paste(rep(c("OneK", "tenK", "tnkp"), each = 2), c("snd", "rot"), sep = "_"))

        dt[, c(paste("total", c_phase, sep = "_"), paste(rep(c_phase, each = length(size)), size, sep = "_")) := 0]
        
        dt[, c("total_duff", 
               "total_litter",
               "total_1",
               "total_10",
               "total_100",
               "total_OneK_snd",
               "total_OneK_rot",
               "total_tenK_snd", 
               "total_tenK_rot",
               "total_tnkp_snd", 
               "total_tnkp_rot") := 0]
        
}
        