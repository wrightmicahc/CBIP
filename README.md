# California Biopower Impact Project: Wildfire and RX Emissions

Calculate wildfire and RX emissions under different silvacultural treatments and biomass utilization scenarios as part of the California Biopower Impact Project, or [CBIP](https://schatzcenter.org/cbip/). The remote repository for this project can be found at [github.com/wrightmicahc/CBIP](https://github.com/wrightmicahc/CBIP).

## Installation

Download or fork the repository from [github.com/wrightmicahc/CBIP](https://github.com/wrightmicahc/CBIP). 

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

This project was written in R using the Rstudio project framework. Occasionally, the existing Consume functions (written in Python) were used for testing, primarily through the rstudio interface with the reticulate package, though jupyter notebooks were also employed.

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

This project is in the Rstudio project format, so all scripts must be sourced relative to the main CBIP folder. The general usage is shown below. In this example, emissions and residual (unconsumed) fuel are estimated for a fixed set of scenarios over five time steps over a 100-year period for tile number 300.

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

All outputs are saved to the "data/Tiles/output" folder. The following code demonstrates how to access the results, which are data.tables saved in .rds format.

```
emissions <- readRDS("data/Tiles/output/emissions/300/20_Proportional_Thin-Cable-Cut_to_Length-Broadcast-None-No-300-0.rds")

residual_fuels <- readRDS("data/Tiles/output/residual_fuels/300/20_Proportional_Thin-Cable-Cut_to_Length-Broadcast-None-No-300-0.rds")
```

## What it does

The model estimates fuel consumption, emissions, and residual fuels for one of 478 fixed scenarios. The scenarios are shown in the following table, which can also be accessed at "data/SERC/scenarios.csv".

|  ID|Silvicultural_Treatment |Harvest_System |Harvest_Type  |Burn_Type |Biomass_Collection |Pulp_Market |
|---:|:-----------------------|:--------------|:-------------|:---------|:------------------|:-----------|
|   1|Clearcut                |Ground         |Whole_Tree    |None      |None               |No          |
|   2|Clearcut                |Ground         |Whole_Tree    |None      |Yes                |No          |
|   3|Clearcut                |Ground         |Whole_Tree    |Pile      |None               |No          |
|   4|Clearcut                |Ground         |Whole_Tree    |Broadcast |None               |No          |
|   5|Clearcut                |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
|   6|Clearcut                |Ground         |Cut_to_Length |None      |None               |No          |
|   7|Clearcut                |Ground         |Cut_to_Length |None      |Yes                |No          |
|   8|Clearcut                |Ground         |Cut_to_Length |Jackpot   |None               |No          |
|   9|Clearcut                |Ground         |Cut_to_Length |Broadcast |None               |No          |
|  10|Clearcut                |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
|  11|Clearcut                |Cable          |Whole_Tree    |None      |None               |No          |
|  12|Clearcut                |Cable          |Whole_Tree    |None      |Yes                |No          |
|  13|Clearcut                |Cable          |Whole_Tree    |Pile      |None               |No          |
|  14|Clearcut                |Cable          |Whole_Tree    |Broadcast |None               |No          |
|  15|Clearcut                |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
|  16|Clearcut                |Cable          |Cut_to_Length |None      |None               |No          |
|  17|Clearcut                |Cable          |Cut_to_Length |None      |Yes                |No          |
|  18|Clearcut                |Cable          |Cut_to_Length |Jackpot   |None               |No          |
|  19|Clearcut                |Cable          |Cut_to_Length |Broadcast |None               |No          |
|  20|Clearcut                |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
|  21|20_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |No          |
|  22|20_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |No          |
|  23|20_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |No          |
|  24|20_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |No          |
|  25|20_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
|  26|20_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |No          |
|  27|20_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |No          |
|  28|20_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
|  29|20_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |No          |
|  30|20_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
|  31|20_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |No          |
|  32|20_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |No          |
|  33|20_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |No          |
|  34|20_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |No          |
|  35|20_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
|  36|20_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |No          |
|  37|20_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |No          |
|  38|20_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
|  39|20_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |No          |
|  40|20_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
|  41|40_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |No          |
|  42|40_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |No          |
|  43|40_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |No          |
|  44|40_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |No          |
|  45|40_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
|  46|40_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |No          |
|  47|40_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |No          |
|  48|40_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
|  49|40_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |No          |
|  50|40_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
|  51|40_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |No          |
|  52|40_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |No          |
|  53|40_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |No          |
|  54|40_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |No          |
|  55|40_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
|  56|40_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |No          |
|  57|40_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |No          |
|  58|40_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
|  59|40_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |No          |
|  60|40_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
|  61|60_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |No          |
|  62|60_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |No          |
|  63|60_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |No          |
|  64|60_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |No          |
|  65|60_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
|  66|60_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |No          |
|  67|60_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |No          |
|  68|60_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
|  69|60_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |No          |
|  70|60_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
|  71|60_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |No          |
|  72|60_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |No          |
|  73|60_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |No          |
|  74|60_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |No          |
|  75|60_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
|  76|60_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |No          |
|  77|60_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |No          |
|  78|60_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
|  79|60_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |No          |
|  80|60_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
|  81|80_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |No          |
|  82|80_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |No          |
|  83|80_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |No          |
|  84|80_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |No          |
|  85|80_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
|  86|80_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |No          |
|  87|80_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |No          |
|  88|80_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
|  89|80_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |No          |
|  90|80_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
|  91|80_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |No          |
|  92|80_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |No          |
|  93|80_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |No          |
|  94|80_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |No          |
|  95|80_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
|  96|80_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |No          |
|  97|80_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |No          |
|  98|80_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
|  99|80_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |No          |
| 100|80_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
| 101|20_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |No          |
| 102|20_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |No          |
| 103|20_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |No          |
| 104|20_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |No          |
| 105|20_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |No          |
| 106|20_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 107|20_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |No          |
| 108|20_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |No          |
| 109|20_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |No          |
| 110|20_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |No          |
| 111|20_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |No          |
| 112|20_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 113|40_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |No          |
| 114|40_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |No          |
| 115|40_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |No          |
| 116|40_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |No          |
| 117|40_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |No          |
| 118|40_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 119|40_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |No          |
| 120|40_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |No          |
| 121|40_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |No          |
| 122|40_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |No          |
| 123|40_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |No          |
| 124|40_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 125|60_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |No          |
| 126|60_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |No          |
| 127|60_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |No          |
| 128|60_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |No          |
| 129|60_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |No          |
| 130|60_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 131|60_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |No          |
| 132|60_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |No          |
| 133|60_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |No          |
| 134|60_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |No          |
| 135|60_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |No          |
| 136|60_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 137|80_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |No          |
| 138|80_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |No          |
| 139|80_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |No          |
| 140|80_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |No          |
| 141|80_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |No          |
| 142|80_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 143|80_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |No          |
| 144|80_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |No          |
| 145|80_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |No          |
| 146|80_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |No          |
| 147|80_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |No          |
| 148|80_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 149|20_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |No          |
| 150|20_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |No          |
| 151|20_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |No          |
| 152|20_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |No          |
| 153|20_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
| 154|20_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |No          |
| 155|20_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |No          |
| 156|20_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 157|20_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |No          |
| 158|20_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
| 159|20_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |No          |
| 160|20_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |No          |
| 161|20_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |No          |
| 162|20_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |No          |
| 163|20_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
| 164|20_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |No          |
| 165|20_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |No          |
| 166|20_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 167|20_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |No          |
| 168|20_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
| 169|40_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |No          |
| 170|40_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |No          |
| 171|40_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |No          |
| 172|40_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |No          |
| 173|40_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
| 174|40_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |No          |
| 175|40_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |No          |
| 176|40_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 177|40_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |No          |
| 178|40_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
| 179|40_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |No          |
| 180|40_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |No          |
| 181|40_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |No          |
| 182|40_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |No          |
| 183|40_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
| 184|40_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |No          |
| 185|40_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |No          |
| 186|40_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 187|40_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |No          |
| 188|40_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
| 189|60_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |No          |
| 190|60_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |No          |
| 191|60_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |No          |
| 192|60_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |No          |
| 193|60_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
| 194|60_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |No          |
| 195|60_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |No          |
| 196|60_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 197|60_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |No          |
| 198|60_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
| 199|60_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |No          |
| 200|60_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |No          |
| 201|60_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |No          |
| 202|60_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |No          |
| 203|60_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
| 204|60_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |No          |
| 205|60_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |No          |
| 206|60_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 207|60_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |No          |
| 208|60_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
| 209|80_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |No          |
| 210|80_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |No          |
| 211|80_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |No          |
| 212|80_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |No          |
| 213|80_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
| 214|80_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |No          |
| 215|80_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |No          |
| 216|80_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 217|80_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |No          |
| 218|80_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
| 219|80_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |No          |
| 220|80_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |No          |
| 221|80_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |No          |
| 222|80_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |No          |
| 223|80_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
| 224|80_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |No          |
| 225|80_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |No          |
| 226|80_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 227|80_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |No          |
| 228|80_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
| 229|Standing_Dead           |Ground         |Whole_Tree    |None      |None               |No          |
| 230|Standing_Dead           |Ground         |Whole_Tree    |None      |Yes                |No          |
| 231|Standing_Dead           |Ground         |Whole_Tree    |Pile      |None               |No          |
| 232|Standing_Dead           |Ground         |Whole_Tree    |Broadcast |None               |No          |
| 233|Standing_Dead           |Ground         |Whole_Tree    |Broadcast |Yes                |No          |
| 234|Standing_Dead           |Ground         |Cut_to_Length |None      |None               |No          |
| 235|Standing_Dead           |Ground         |Cut_to_Length |None      |Yes                |No          |
| 236|Standing_Dead           |Ground         |Cut_to_Length |Jackpot   |None               |No          |
| 237|Standing_Dead           |Ground         |Cut_to_Length |Broadcast |None               |No          |
| 238|Standing_Dead           |Ground         |Cut_to_Length |Broadcast |Yes                |No          |
| 239|Standing_Dead           |Cable          |Whole_Tree    |None      |None               |No          |
| 240|Standing_Dead           |Cable          |Whole_Tree    |None      |Yes                |No          |
| 241|Standing_Dead           |Cable          |Whole_Tree    |Pile      |None               |No          |
| 242|Standing_Dead           |Cable          |Whole_Tree    |Broadcast |None               |No          |
| 243|Standing_Dead           |Cable          |Whole_Tree    |Broadcast |Yes                |No          |
| 244|Standing_Dead           |Cable          |Cut_to_Length |None      |None               |No          |
| 245|Standing_Dead           |Cable          |Cut_to_Length |None      |Yes                |No          |
| 246|Standing_Dead           |Cable          |Cut_to_Length |Jackpot   |None               |No          |
| 247|Standing_Dead           |Cable          |Cut_to_Length |Broadcast |None               |No          |
| 248|Standing_Dead           |Cable          |Cut_to_Length |Broadcast |Yes                |No          |
| 249|Clearcut                |Ground         |Whole_Tree    |None      |None               |Yes         |
| 250|Clearcut                |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 251|Clearcut                |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 252|Clearcut                |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 253|Clearcut                |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 254|Clearcut                |Ground         |Cut_to_Length |None      |None               |Yes         |
| 255|Clearcut                |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 256|Clearcut                |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 257|Clearcut                |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 258|Clearcut                |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 259|Clearcut                |Cable          |Whole_Tree    |None      |None               |Yes         |
| 260|Clearcut                |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 261|Clearcut                |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 262|Clearcut                |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 263|Clearcut                |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 264|Clearcut                |Cable          |Cut_to_Length |None      |None               |Yes         |
| 265|Clearcut                |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 266|Clearcut                |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 267|Clearcut                |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 268|Clearcut                |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 269|20_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 270|20_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 271|20_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 272|20_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 273|20_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 274|20_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 275|20_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 276|20_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 277|20_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 278|20_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 279|20_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 280|20_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 281|20_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 282|20_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 283|20_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 284|20_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 285|20_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 286|20_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 287|20_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 288|20_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 289|40_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 290|40_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 291|40_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 292|40_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 293|40_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 294|40_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 295|40_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 296|40_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 297|40_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 298|40_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 299|40_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 300|40_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 301|40_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 302|40_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 303|40_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 304|40_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 305|40_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 306|40_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 307|40_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 308|40_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 309|60_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 310|60_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 311|60_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 312|60_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 313|60_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 314|60_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 315|60_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 316|60_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 317|60_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 318|60_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 319|60_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 320|60_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 321|60_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 322|60_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 323|60_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 324|60_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 325|60_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 326|60_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 327|60_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 328|60_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 329|80_Thin_from_Below      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 330|80_Thin_from_Below      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 331|80_Thin_from_Below      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 332|80_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 333|80_Thin_from_Below      |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 334|80_Thin_from_Below      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 335|80_Thin_from_Below      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 336|80_Thin_from_Below      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 337|80_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 338|80_Thin_from_Below      |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 339|80_Thin_from_Below      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 340|80_Thin_from_Below      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 341|80_Thin_from_Below      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 342|80_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 343|80_Thin_from_Below      |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 344|80_Thin_from_Below      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 345|80_Thin_from_Below      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 346|80_Thin_from_Below      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 347|80_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 348|80_Thin_from_Below      |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 349|20_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 350|20_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 351|20_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 352|20_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 353|20_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 354|20_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 355|20_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 356|20_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 357|20_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 358|20_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 359|20_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 360|20_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 361|40_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 362|40_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 363|40_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 364|40_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 365|40_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 366|40_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 367|40_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 368|40_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 369|40_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 370|40_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 371|40_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 372|40_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 373|60_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 374|60_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 375|60_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 376|60_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 377|60_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 378|60_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 379|60_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 380|60_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 381|60_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 382|60_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 383|60_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 384|60_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 385|80_Thin_from_Above      |Ground         |Whole_Tree    |None      |None               |Yes         |
| 386|80_Thin_from_Above      |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 387|80_Thin_from_Above      |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 388|80_Thin_from_Above      |Ground         |Cut_to_Length |None      |None               |Yes         |
| 389|80_Thin_from_Above      |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 390|80_Thin_from_Above      |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 391|80_Thin_from_Above      |Cable          |Whole_Tree    |None      |None               |Yes         |
| 392|80_Thin_from_Above      |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 393|80_Thin_from_Above      |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 394|80_Thin_from_Above      |Cable          |Cut_to_Length |None      |None               |Yes         |
| 395|80_Thin_from_Above      |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 396|80_Thin_from_Above      |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 397|20_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |Yes         |
| 398|20_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 399|20_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 400|20_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 401|20_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 402|20_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |Yes         |
| 403|20_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 404|20_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 405|20_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 406|20_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 407|20_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |Yes         |
| 408|20_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 409|20_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 410|20_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 411|20_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 412|20_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |Yes         |
| 413|20_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 414|20_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 415|20_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 416|20_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 417|40_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |Yes         |
| 418|40_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 419|40_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 420|40_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 421|40_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 422|40_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |Yes         |
| 423|40_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 424|40_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 425|40_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 426|40_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 427|40_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |Yes         |
| 428|40_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 429|40_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 430|40_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 431|40_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 432|40_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |Yes         |
| 433|40_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 434|40_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 435|40_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 436|40_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 437|60_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |Yes         |
| 438|60_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 439|60_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 440|60_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 441|60_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 442|60_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |Yes         |
| 443|60_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 444|60_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 445|60_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 446|60_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 447|60_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |Yes         |
| 448|60_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 449|60_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 450|60_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 451|60_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 452|60_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |Yes         |
| 453|60_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 454|60_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 455|60_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 456|60_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 457|80_Proportional_Thin    |Ground         |Whole_Tree    |None      |None               |Yes         |
| 458|80_Proportional_Thin    |Ground         |Whole_Tree    |None      |Yes                |Yes         |
| 459|80_Proportional_Thin    |Ground         |Whole_Tree    |Pile      |None               |Yes         |
| 460|80_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |None               |Yes         |
| 461|80_Proportional_Thin    |Ground         |Whole_Tree    |Broadcast |Yes                |Yes         |
| 462|80_Proportional_Thin    |Ground         |Cut_to_Length |None      |None               |Yes         |
| 463|80_Proportional_Thin    |Ground         |Cut_to_Length |None      |Yes                |Yes         |
| 464|80_Proportional_Thin    |Ground         |Cut_to_Length |Jackpot   |None               |Yes         |
| 465|80_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |None               |Yes         |
| 466|80_Proportional_Thin    |Ground         |Cut_to_Length |Broadcast |Yes                |Yes         |
| 467|80_Proportional_Thin    |Cable          |Whole_Tree    |None      |None               |Yes         |
| 468|80_Proportional_Thin    |Cable          |Whole_Tree    |None      |Yes                |Yes         |
| 469|80_Proportional_Thin    |Cable          |Whole_Tree    |Pile      |None               |Yes         |
| 470|80_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |None               |Yes         |
| 471|80_Proportional_Thin    |Cable          |Whole_Tree    |Broadcast |Yes                |Yes         |
| 472|80_Proportional_Thin    |Cable          |Cut_to_Length |None      |None               |Yes         |
| 473|80_Proportional_Thin    |Cable          |Cut_to_Length |None      |Yes                |Yes         |
| 474|80_Proportional_Thin    |Cable          |Cut_to_Length |Jackpot   |None               |Yes         |
| 475|80_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |None               |Yes         |
| 476|80_Proportional_Thin    |Cable          |Cut_to_Length |Broadcast |Yes                |Yes         |
| 477|No_Action               |None           |None          |None      |None               |No          |
| 478|No_Action               |None           |None          |Broadcast |None               |No          |

The model loads pre-processed spatial attributes that have been converted to a tabular format with x-y location indicator columns. All spatial data use the California (Teale) Albers projetion. The CRS is below:

```
CRS arguments:
 +proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=m
+no_defs +ellps=GRS80 +towgs84=0,0,0 
```

The existing fuelbed and treatment residue data are then appended to the spatial attribute data using FCCS and updated GNN FCID identifiers. The post-treatment fuelbed is then created by adding the treatment residue to the exisiting fuelbed using proportions assigned for each scenario. Burns are then simulated for each fuelbed at 25-year increments over a 100-year period for a total of five model runs in each scenario. Both the emissions and residual fuels (treatment residue only) are saved following each simulation. Wildfire simulations assume that no previous wildfire has occurred. For scenarios that include an RX burn, the RX burn occurs at year 0, and all subsequent burns are modeled as wildfires. These follow-up wildfires are simulated using the remaining treatment residue that has been added to a "recovered" fuelbed. Treatment residues are updated to reflect mass loss from decay prior to burning for all cases.

To estimate emissions, all consumed mass is multiplied by phase-specific (flaming, smoldering, and residual) FEPs emissons factors, which are taken from the [Bluesky modeling framework](https://github.com/pnwairfire/eflookup/blob/master/eflookup/fepsef.py). Char production is also modeled. All mass converted to char is assumed to come from unconsumed fuel. The model output is then split into seperate data.tables containing residual fuels and emissions estimates and is saved as .rds files.

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
