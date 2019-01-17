################################################################################
# This script contains unit tests for char production functions
#
# Author: Micah Wright, Humboldt State University
################################################################################

# generate data
df <- data.frame(residue = rep(10, 10),
                 consumed = seq(0, 10, length.out = 10))

# calculate charcoal prop of total mass
df$chrcl_prop <- (11.30534 + -0.63064 * df$consumed) / 100

# plot it
plot(df$consumed, df$chrcl_prop)

# check that no values are < 0 or > 1
table(df$chrcl_prop < 0 & df$chrcl_prop > 1)

# calculate the actual char in tons/acre
df$chrcl_tonsacre <- df$residue * df$chrcl_prop

# plot it
plot(df$consumed, df$chrcl_tonsacre)

# check that no values are > 10
table(df$chrcl_tonsacre > 10)
