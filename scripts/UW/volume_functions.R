# fustrum of cone volume function
fust_v <- function(DBH) {
        # base radius
        R <- (DBH * 1.10) / 2 
        # top radius
        r <- (DBH * 1.05) / 2
        # volume
        fv <- ((pi/3) * 12) * (R^2 + (R * r) + r^2)
        return(fv)
}

# cone volume function for height above 1' stump
cone_v <- function(r, h) {
        
        (pi * r^2) * (h/3)
        
}

# get stem height at radius r
h_at_r <- function(R, h, r) {
        
        (-h/R) * r + h
        
}


getstem_fun <- function(dt) {
        
        # copy dt 
        dtc <- copy(dt)
        
        # convert height to inches
        dtc[, h_in := HtHard * 12]
        
        # diameter of top of 1' stump
        dtc[, r_base := (DBH * 1.05) / 2]
        
        # height above 1' stump
        dtc[, h_stem := h_in - 12]
        
        # stem volume (not including 1' stump)
        dtc[, vol_stem := cone_v(r_base, h_stem)]
        
        # stump volume assuming 1'
        dtc[, vol_stump := fust_v(DBH)]
        
        # get height at each diameter: 9, 6, and 4"
        dtc[, ht_9 := h_at_r(r_base, h_stem, 9/2)]
        dtc[, ht_6 := h_at_r(r_base, h_stem, 6/2)]
        dtc[, ht_4 := h_at_r(r_base, h_stem, 4/2)]
        
        # get volume for each size class
        # <4"
        dtc[, vol_lt4 := cone_v(r_base, h_stem)]
        dtc[r_base > 4/2, vol_lt4 := cone_v(4/2, h_stem - ht_4)]
        
        # 4-6"
        dtc[, vol_4t6 := cone_v(r_base, h_stem) - vol_lt4]
        dtc[r_base > 6/2, vol_4t6 := cone_v(6/2, h_stem - ht_6) - vol_lt4]
        dtc[ht_4 < 0, vol_4t6 := 0]
        
        # 6-9"
        dtc[, vol_6t9 := cone_v(r_base, h_stem) - (vol_lt4 + vol_4t6)]
        dtc[r_base > 9/2, vol_6t9 := cone_v(9/2, h_stem - ht_9) - (vol_lt4 + vol_4t6)]
        dtc[ht_6 < 0, vol_6t9 := 0]
        
        # >9"
        dtc[, vol_ge9 := vol_stem - (vol_lt4 + vol_4t6 + vol_6t9)]
        dtc[ht_9 < 0, vol_ge9 := 0]
        
        dtc[, vol_total := vol_lt4 + vol_4t6 + vol_6t9 + vol_ge9 + vol_stump]

        dtc[, vol_lt4_p := vol_lt4 / vol_total] 
        dtc[, vol_4t6_p := vol_4t6 / vol_total] 
        dtc[, vol_6t9_p := vol_6t9 / vol_total] 
        dtc[, vol_ge9_p := vol_ge9 / vol_total]
        dtc[, vol_stump_p := vol_stump / vol_total]

        dtc[, c("h_in",
                "r_base",
                "h_stem",
                "vol_stem",
                "vol_stump",
                "ht_9", 
                "ht_6",
                "ht_4",
                "vol_lt4",
                "vol_4t6",
                "vol_6t9",
                "vol_ge9",
                "vol_total") := NULL]
        
        return(dtc)

}
