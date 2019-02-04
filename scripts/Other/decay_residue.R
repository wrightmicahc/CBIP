################################################################################
# This script decays treatment residues as part of the California Biopower 
# Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# decay function for everything but foliage
decay_fun <- function(residue, k_val, t) {
        
        return(residue * exp(-k_val * t))
        
}

# decay function that either calculates decayed foliage or additions to duff
# depending on a toggle
decay_foliage <- function(residue, k_val, t, toggle) {
        
        decayed <- decay_fun(residue, k_val, t)
        
        if(toggle == "foliage") {
                
                decayed_adj <- ifelse(decayed >= residue * 0.5, decayed, 0)
                
                return(decayed_adj)
        }
        
        if(toggle == "duff") {
                
                decayed_adj <- ifelse(decayed < residue * 0.5, decayed, 0)
                
                return(decayed_adj)
        }
}

# add woody fuels to duff at 2% of decayed mass per year
to_duff <- function(residue, k_val, t) {
        
        ifelse(t == 0, 0, (decay_fun(residue, k_val, t - 1) - decay_fun(residue, k_val, t)) * 0.02)
        
}
