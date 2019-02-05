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

# decay function that calculates decayed foliage and additions to duff
decay_foliage <- function(residue, k_val, t) {
        
        decayed <- decay_fun(residue, k_val, t)
        
        still_litter <- decayed >= residue * 0.5
        
        decayed_adj <- ifelse(still_litter, decayed, 0)
        
        dfa <- ifelse(still_litter, to_duff(residue, k_val, t), 
                      decay_fun(residue, 0.002, t))
        
        return(list("decay" = decayed_adj, "duff" = dfa))
}

# add woody fuels to duff at 2% of decayed mass per year
to_duff <- function(residue, k_val, t) {
        
        # make a sequence of numbers from 0-t
        tn <- seq(0, t, 1)
        
        # create a list of residue to be added to duff for every year in the sequence
        dfa_list <- lapply(tn, function(i) {
                
                added <- ifelse(i == 0, 0, (decay_fun(residue, k_val, i - 1) - decay_fun(residue, k_val, i)) * 0.02)
                
        })
        
        duff_added <- sum(unlist(dfa_list))
        
        net <- decay_fun(duff_added, 0.002, t)
        
        return(net)
        
}
