################################################################################
# This script calculates the coefficients for charcoal production based on fuel 
# consumed as part of the California Biopower Impact Project.
#
# Author: Micah Wright, Humboldt State University
################################################################################
# define data
# values taken from figure 3 in Pingree et al. 2012 "Long and Short-Term Effects
# of Fire on Soil Charcoal of a Conifer Forest in Southwest Oregon"
chrcl <- data.frame(fuel_consumed_tonsAcre = c(15.5,
                                               12.5,
                                               12.4,
                                               8.7,
                                               6.4,
                                               5.6),
                    char_produced_percent = c(1.6,
                                              3.2,
                                              3.9,
                                              5.2,
                                              7.2,
                                              8.2))

# model
chrcl_mod <- lm(char_produced_percent ~ fuel_consumed_tonsAcre, data = chrcl)

# plot results
plot(chrcl$fuel_consumed_tonsAcre, chrcl$char_produced_percent,
     xlab = "Fuel Consumed (Tons/Acre)",
     ylab = "Char Produced (%)")
abline(chrcl_mod)

# look at the summary
summary(chrcl_mod)

# get coefficients
chrcl_coef <- coef(chrcl_mod)

chrcl_coef

# save
saveRDS(chrcl_coef, "data/Other/charcoal/chrcl_coef.rds")
