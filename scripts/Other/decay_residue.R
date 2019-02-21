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
        
        y <- 0:100
                          
        yd <- ifelse(exp(-k_val * y) >= 0.5, y, NA)
        
        my <- max(yd, na.rm = TRUE)
        
        return(my)
        
}

fifty_fun_vect <- Vectorize(fifty_fun)

# add woody fuels to duff at 2% of decayed mass per year and decay previously 
# added mass
to_duff <- function(residue, k_val, t) {
        
        # make a sequence of numbers from 0-t
        tn <- 0:t
        
        # create a list of residue to be added to duff for every year in the sequence
        added <- ifelse(tn == 0, 0, (decay_fun(residue, k_val, tn - 1) - decay_fun(residue, k_val, tn)) * 0.02)
        
        duff_added <- sum(added)
        
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
        
        last_year <- fifty_fun_vect(k_val)
        
        dfa <- ifelse(still_litter, to_duff_vect(residue, k_val, t), 
                      decay_fun(decay_fun(residue, k_val, last_year), 0.002, t - last_year))
        
        if(toggle == "foliage") {
                
                return(decayed_adj)
        }
        
        if(toggle == "duff") {
                
                return(dfa)
        }
}

# function for woody fuels with transition from sound to rotten at 64%
decay_woody <- function(residue, k_val, t, toggle) {
        
        decayed <- decay_fun(residue, k_val, t)
        
        still_sound <- decayed >= residue * 0.64
        
        decayed_sound <- ifelse(still_sound, decayed, 0)
        
        decayed_rotten <- ifelse(!still_sound, decayed, 0)
        
        if(toggle == "sound") {
                
                return(decayed_sound)
        }
        
        if(toggle == "rotten") {
                
                return(decayed_rotten)
        }
        
}
