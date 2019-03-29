---
date: '`r format(Sys.Date(), "%B %d, %Y")`'
output: html_document
---

# California Biopower Impact Project: Wildfire Emissions

Calculate wildfire and RX emissions under different silvacultural treatments and biomass utilization scenarios as part of the California Biopower Impact Project (CBIP). The remote repository for this project can be found at [https://github.com/wrightmicahc/CBIP](https://github.com/wrightmicahc/CBIP).

## Installation

Download or fork the repository from [https://github.com/wrightmicahc/CBIP](https://github.com/wrightmicahc/CBIP). 

## File Structure

The file structure is shown in the following tree. 

```
CBIP                            # main project directory
+-- CBIP.Rproj                  # r-project file
+-- README.html                 # readme
+-- Consume4_2                  # original Consume source code
+-- data                        # main data directory 
|   +-- FCCS                    # FCCS fuels data
|   +-- GAP                     # Landcover class data
|   +-- GEE                     # Google Earth Engine data
|   +-- Other                   # directory for misc. data sets
|   +-- UW                      # UW data directory
|   +-- Tiles                   # Tile shapefiles, tiled input and output data
                                  sets
+-- scripts                     # main script directory
|   +-- Consume                 # consume, r version
|   +-- FCCS                    # existing fuelbed processing
|   +-- GAP                     # landcover classification
|   +-- GEE                     # Google earth engine data processing
|   +-- Other                   # misc. scripts
|   +-- emissions_model         # core scripts for the emissions model excluding
|                                 consumption/emissions scripts
|   +-- Test                    # scratch and testing scripts
|   +-- UW                      # residue data processing 
+-- figures                     # figures
```

## Prerequisites

This project was written in R using the Rstudio project framework. Occasionally, existing Consume Python scripts were used for testing, primarily through the rstudio interface with the reticulate package, though jupyter notebooks were also employed.

### Software requirements

To run the main scenario_emissions function, the following is required:

* A current version of R
* A current version of Rstudio
* The following R packages and their dependencies:
        - future.apply 
        - data.table
        - sf 
* The CBIP Rstudio project 
* At least 6GB storage per tile. [^1]

[^1]: This has not been thoroughly tested for all possible tiles. More storage is better.
        
Packages can be installed as follows:

```
install.packages("data.table")
```

Other packages and software are required to reproduce the entire project, inlcuding python, Consume 4.2, Google Earth Engine, and many other r packages. Packages were loaded at the beginning of every script where possible. All scripts have a description header.

## Usage

This project is in the Rstudio project format, so all scripts must be sourced relative to the main CBIP folder. The general usage is shown below. In this example, emissions and residual (unconsumed) fuel are estimated for five time steps over a 100-year period for tile number 300 .

```
source("scripts/emissions_model/scenario_emissions.R")

tile_number <- 300

scenario_emissions(tile_number)
```

Tile number must match one of the ID numbers of the ~2669 hectare tiles located in "data/Tiles/clipped_tiles/clipped_tiles.shp". The tile ID numbers can be extracted using the following snippet:

```
tiles <- sf::st_read("data/Tiles/clipped_tiles/clipped_tiles.shp")
tiles$ID
```

The scenario_emissions function impliments parrallel processing using the future.apply package, which should be platform independent. 

A scenario 

## What it does

The model loads pre-processed spatial attributes that have been converted to a tabular format with x-y location indicator columns. All spatial data use the California (Teale) Albers projetion. The CRS is below:

```
CRS arguments:
 +proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=m
+no_defs +ellps=GRS80 +towgs84=0,0,0 
```

The existing fuelbed and treatment residue data are then appended to the spatial attribute data using FCCS and updated GNN FCID indicators, which vary spatially. The post-treatment fuelbed is then created by adding the residue to the exisiting fuelbed using proportions assigned for each scenario. Burns are then simulated for each fuelbed at 25-year increments over a 100-year period for a total of five model runs in each scenario. Both the emissions and residual fuels are saved following each simulation, wildfire simulations assume that no previous wildfire has occurred. For scenarios that include an RX burn, the RX burn occurs at year 0, and all subsequent burns are wildfire on the remaining fuelbed. Fuels are updated to reflect decay prior to burning for all cases.

Consumed material is then multiplied by phase-specific emissons factors to estimate fire emissions. Char production is also modeled. The saved otputs include residual fuels and emissions for each scenario in each tile.

## Output description

The scenario_emissions function saves two output files for each scenario:

1. emissions 

2. residual_fuels

These are saved as .rds files in folders of the same name located in data/Tiles/output. File naming convention is folders for output type and tile_number, then Silvicultural_Treatment, Harvest_System, Harvest_Type, Burn_Type, Biomass_Collection, Pulp_Market, tile_number, and year with "-" seperation. An example:

```
output/emissions/657/20_Proportional_Thin-Cable-Cut_to_Length-Broadcast-None-No-657-0.rds
```                                    

### Emissions

The emissions table has the following columns:

```
x: x coordinate of cell.
y: y coordinate of cell.
fuelbed_number: FCCS fuelbed number.
FCID2018: UW FCID number for 2018.
ID: Integer scenario ID number, unique to each scenario treatment combination.
Silvicultural_Treatment: Harvest or fuel treatment method applied.
Harvest_Type: Harvest method, whole tree or cut-to-length.
Harvest_System: Harvest extraction method, cable or ground.
Burn_Type: RX burn type for the scenario, if applicable.
Biomass_Collection: Was the biomass collected for energy generation?
Pulp_Market: Was there a pulp market?
Year: year in 100-year sequence.
total_except_pile_char: char produced by scattered fuels in tons/acre including original fuelbed.
total_except_pile_CH4: CH4 produced by scattered fuels in tons/acre including original fuelbed. 
total_except_pile_CO: CO produced by scattered fuels in tons/acre including original fuelbed.
total_except_pile_CO2: CO2 produced by scattered fuels in tons/acre including original fuelbed.
total_except_pile_NOx: NOx produced by scattered fuels in tons/acre including original fuelbed.
total_except_pile_PM10: PM10 produced by scattered fuels in tons/acre including original fuelbed.
total_except_pile_PM2.5: PM2.5 produced by scattered fuels in tons/acre including original fuelbed.
total_except_pile_SO2: SO2 produced by scattered fuels in tons/acre including original fuelbed.
total_except_pile_VOC: VOC produced by scattered fuels in tons/acre including original fuelbed.
total_pile_clean_PM10: PM10 from piled fuels in tons/acre assuming clean piles.
total_pile_vdirty_PM10: PM10 from piled fuels in tons/acre assuming very dirty piles.
total_pile_clean_PM2.5: PM2.5 from piled fuels in tons/acre assuming clean piles.
total_pile_vdirty_PM2.5: PM2.5 from piled fuels in tons/acre assuming very dirty piles.
total_pile_CH4: CH4 from piled fuels in tons/acre.
total_pile_CO: CO from piled fuels in tons/acre.           
total_pile_CO2: CO2 from piled fuels in tons/acre.
total_pile_NOx: NOx from piled fuels in tons/acre.
total_pile_SO2: SO2 from piled fuels in tons/acre.
total_pile_VOC: VOC from piled fuels in tons/acre.
pile_char: char from piled fuels  in tons/acre.
char_fwd_residue: char from fine woody debris (1-3") in tons/acre.
char_cwd_residue: char from coarse woody debris (>3") in tons/acre
total_duff_exposed: duff exposed to fire that began as residue in tons/acre.
total_foliage_exposed: residue foliage exposed to fire in tons/acre.
total_fwd_exposed: residue fine woody debris (1-3") exposed to fire in tons/acre.
total_cwd_exposed: residue coarse woody debris (>3") exposed to fire in tons/acre.
total_fuel_consumed: total biomass consumed in tons/acre, including piled fuels.
total_duff_consumed: residue duff consumed in tons/acre.
total_foliage_consumed: residue foliage consumed in tons/acre.
total_fwd_consumed: residue fine woody debris (1-3") consumed in tons/acre.
total_cwd_consumed: residue coarse woody debris (>3") consumed in tons/acre.
total_duff_residue_CH4: CH4 produced by residue duff in tons/acre.
total_foliage_residue_CH4: CH4 produced by residue foliage in tons/acre.
total_fwd_residue_CH4: CH4 produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_CH4: CH4 produced by residue coarse woody debris (>3") in tons/acre.
total_duff_residue_CO: CO produced by residue duff in tons/acre.
total_foliage_residue_CO: CO produced by residue foliage in tons/acre.
total_fwd_residue_CO: CO produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_CO: CO produced by residue coarse woody debris (>3") in tons/acre.
total_duff_residue_CO2: CO2 produced by residue duff in tons/acre.
total_foliage_residue_CO2: CO2 produced by residue foliage in tons/acre.
total_fwd_residue_CO2: CO2 produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_CO2: CO2 produced by residue CO2arse woody debris (>3") in tons/acre.
total_duff_residue_NOx: NOx produced by residue duff in tons/acre.
total_foliage_residue_NOx: NOx produced by residue foliage in tons/acre.
total_fwd_residue_NOx: NOx produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_NOx: NOx produced by residue NOxarse woody debris (>3") in tons/acre.
total_duff_residue_PM10: PM10 produced by residue duff in tons/acre.
total_foliage_residue_PM10: PM10 produced by residue foliage in tons/acre.
total_fwd_residue_PM10: PM10 produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_PM10: PM10 produced by residue PM10arse woody debris (>3") in tons/acre.
total_duff_residue_PM2.5: PM2.5 produced by residue duff in tons/acre.
total_foliage_residue_PM2.5: PM2.5 produced by residue foliage in tons/acre.
total_fwd_residue_PM2.5: PM2.5 produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_PM2.5: PM2.5 produced by residue PM2.5arse woody debris (>3") in tons/acre.
total_duff_residue_SO2: SO2 produced by residue duff in tons/acre.
total_foliage_residue_SO2: SO2 produced by residue foliage in tons/acre.
total_fwd_residue_SO2: SO2 produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_SO2: SO2 produced by residue SO2arse woody debris (>3") in tons/acre.
total_duff_residue_VOC: VOC produced by residue duff in tons/acre.
total_foliage_residue_VOC: VOC produced by residue foliage in tons/acre.
total_fwd_residue_VOC: VOC produced by residue fine woody debris (1-3") in tons/acre.
total_cwd_residue_VOC: VOC produced by residue VOCarse woody debris (>3") in tons/acre.
```
### Residual Fuels

The residual fuels table has the following columns.

```
x: x coordinate of cell.
y: y coordinate of cell.
fuelbed_number: FCCS fuelbed number.
FCID2018: UW FCID number for 2018.
ID: Integer scenario ID number, unique to each scenario treatment combination.
Silvicultural_Treatment: Harvest or fuel treatment method applied.
Harvest_Type: Harvest method, whole tree or cut-to-length.
Harvest_System: Harvest extraction method, cable or ground.
Burn_Type: RX burn type for the scenario, if applicable.
Biomass_Collection: Was the biomass collected for energy generation?
Pulp_Market: Was there a pulp market?
Year: year in 100-year sequence.
Slope: Slope of pixel in percent.
Fm10: 10-hour fuel moisture in percent.
Fm1000: 1,000-hour fuel moisture in percent.
Wind_corrected: Corrected windspeed, miles per hour.
duff_upper_loading: Upper duff layer loading, residue only, in tons/acre.
litter_loading: litter loading, residue only, in tons/acre.
one_hr_sound: one-hour (<=0.25") fuel loading, residue only, in tons/acre.
ten_hr_sound: ten-hour (0.26-1") fuel loading, residue only, in tons/acre.           
hun_hr_sound: hundred-hour (1.1-3") fuel loading, residue only, in tons/acre.
oneK_hr_sound: one thousand-hour (3-9") sound fuel loading, residue only, in tons/acre.
oneK_hr_rotten: one thousand-hour (3-9") rotten fuel loading, residue only, in tons/acre.
tenK_hr_sound: ten thousand-hour (9-20") sound fuel loading, residue only, in tons/acre.
tenK_hr_rotten: ten thousand-hour (9-20") rotten fuel loading, residue only, in tons/acre.
tnkp_hr_sound: greater than ten thousand-hour (>20") sound fuel loading, residue only, in tons/acre.
tnkp_hr_rotten: greater than ten thousand-hour (>20") rotten fuel loading, residue only, in tons/acre.
pile_field: field-piled residue of all size classes, in tons/acre.
pile_landing: landing-piled residue of all size classes, in tons/acre.
```

## Versioning

We use [git](https://git-scm.com/) for version control on this project. For a comoplete history, see the [this repository](https://github.com/wrightmicahc/CBIP). 

## Authors

* Micah Wright  - [Github](https://github.com/wrightmicahc/CBIP)

## Acknowledgments

* The R consume scripts were originally translated directly into R from the original python code from Consume 4.2, a component of Fuel Fire Tools. 
