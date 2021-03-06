################################################################################
# This script decays treatment residues as part of the California Biopower 
# Impact Project. 
#
# Author: Micah Wright, Humboldt State University
################################################################################

# basic decay function 
decay_fun <- function(residue, k_val, t) {
        
        return(residue * exp(-k_val * t))
        
}

# function to add woody fuels to duff at 2% of decayed mass per year and decay  
# previously added mass
to_duff <- function(residue, k_val, t) {
        
        duff_added <- (decay_fun(residue, k_val, 0) - decay_fun(residue, k_val, t)) * 0.02
        
        net <- decay_fun(duff_added, 0.002, t)
        
        return(net)
        
}

# foliage-specific function that calculates decayed foliage and additions to duff
decay_foliage <- function(residue, k_val, t, toggle) {
        
        decayed <- decay_fun(residue, k_val, t)
        
        still_litter <- decayed >= residue * 0.5
        
        decayed_adj <- ifelse(still_litter, decayed, 0)
        
        last_year <- floor(log(0.5) / -k_val)
        
        dfa <- ifelse(still_litter, to_duff(residue, k_val, t), 
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
        
        k_soft <- log(1 - k_val) / log(0.64)
        
        to_soft <- residue - decay_fun(residue, k_soft, t)
        
        still_sound <- decayed >= residue * 0.64
        
        decayed_sound <- ifelse(still_sound, decayed - to_soft, 0)
        
        decayed_rotten <- ifelse(!still_sound, decayed, to_soft)
        
        if(toggle == "sound") {
                
                return(decayed_sound)
        }
        
        if(toggle == "rotten") {
                
                return(decayed_rotten)
        }
        
}
