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

# function to determine the last year that the foliage was above the 50%
# threshold
fifty_fun <- function(k_val) {
        
        y <- seq(0, 100, 1)
                          
        yd <- unlist(lapply(y, function(x) {
                if(exp(-k_val * x) >= 0.5) {
                        return(x)
                }
                        }))
        
        my <- max(yd)
        
        return(my)
        
}

fifty_fun_vect <- Vectorize(fifty_fun)

# add woody fuels to duff at 2% of decayed mass per year and decay previously 
# added mass
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

# vectorize to_duff
to_duff_vect <- Vectorize(to_duff)

# decay function that calculates decayed foliage and additions to duff
decay_foliage <- function(residue, k_val, t, toggle) {
        
        decayed <- decay_fun(residue, k_val, t)
        
        still_litter <- decayed >= residue * 0.5
        
        decayed_adj <- ifelse(still_litter, decayed, 0)
        
        last_year <- ifelse(residue == 0, 0, fifty_fun_vect(residue, k_val))
        
        dfa <- ifelse(still_litter, to_duff_vect(residue, k_val, t), 
                      decay_fun(decay_fun(residue, k_val, last_year), 0.002, t - last_year))
        
        if(toggle == "foliage") {
                
                return(decayed_adj)
        }
        
        if(toggle == "duff") {
                
                return(dfa)
        }
}
