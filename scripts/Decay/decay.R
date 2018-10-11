################################################################################
# This script decays biomass residues over a 100-year period. It requires the 
# data.table package.
#
# k_path: the file path to the weighted k-value csv
# residue: the residue data.table
# 
# Author: Micah Wright
################################################################################

decay_fun <- function(residue, k_path) {
        
        # load weighted k
        k_vals <- fread(k_path) 
                      
        # filter weighted k to match residue by FCID
        k_vals <- k_vals[FCID %in% residue$FCID2018]
        
        # rename and keep columns of interest
        k_vals <- k_vals[, .(FCID2018 = FCID, 
                             Foliage = Weighted_K_foliage,
                             Fine = Fine,
                             Coarse = Coarse)]
        
        # merge weighted k and residue
        residue <- merge(residue, k_vals, by = "FCID2018")
        
        # split residue by FCID
        residue_list <- split(residue, residue$FCID2018)
        
        # define simple decay function
        decay_fun <- function(residue, k, t) {
                return(residue * exp(-k * t))
        }
        
        # create a list with a data.table of residues over 100 yrs for each FCID 
        decay_list <- mclapply(residue_list, 
                               mc.cores = detectCores() - 1,
                               function(x){
                                       out_l <- lapply(seq(1, 100), function(i) {
                                               # decay each size class
                                               decay_i <- x[, .(FCID2018 = FCID2018,
                                                                Treatment = Treatment,
                                                                Year = i,
                                                                Foliage_tonsAcre = decay_fun(Foliage_tonsAcre,
                                                                                             Foliage, 
                                                                                             i),
                                                                Branch_tonsAcre = decay_fun(Branch_tonsAcre,
                                                                                            Fine,
                                                                                            i),
                                                                Pulp_4t9_tonsAcre = decay_fun(Pulp_4t9_tonsAcre,
                                                                                              Coarse,
                                                                                              i),
                                                                Break_4t9_tonsAcre = decay_fun(Break_4t6_tonsAcre,
                                                                                               Coarse,
                                                                                               i),
                                                                Break_ge9_tonsAcre = decay_fun(Break_ge9_tonsAcre,
                                                                                               Coarse,
                                                                                               i))]
                                               # calculate duff addition from each year
                                               decay_i$Annual_Duff_tonsAcre <- rowSums(decay_i[, c("Foliage_tonsAcre",
                                                                                                   "Branch_tonsAcre",
                                                                                                   "Pulp_4t9_tonsAcre",
                                                                                                   "Break_4t9_tonsAcre",
                                                                                                   "Break_ge9_tonsAcre")]) * 0.02
                                               
                                               return(decay_i)
                                               
                                       })
                                       
                                       # combine list to single data.table for FCID
                                       out_df <- do.call("rbind", out_l)
                                       
                                       # calculate duff decay
                                       out_df$Duff_tonsAcre <- decay_fun(cumsum(out_df$Annual_Duff_tonsAcre),
                                                                         0.002,
                                                                         out_df$Year)
                                       
                                       return(out_df)
                               })
        
        # combine all FCID data.tables
        decay <- do.call("rbind", decay_list)
        
        return(decay)
}
