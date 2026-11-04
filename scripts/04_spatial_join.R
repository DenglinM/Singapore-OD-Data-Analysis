# Author: AR5302 project / Codex
# Purpose: STEP 1 MRT exits and bus stops -> Master Plan 2019 subzones.
# Inputs: config/spatial_join.R; local spatial inputs and station crosswalk.
# Outputs: lookup CSVs and audit tables in data/processed/spatial_join/.
# Run from the repository root, or open the .Rproj first.
for (p in c("sf", "readr")) {
  if (!requireNamespace(p, quietly = TRUE)) stop("Install required package: ", p)
}
source("R/spatial_join.R")
config_path <- Sys.getenv("AR5302_SPATIAL_CONFIG", "config/spatial_join.R")
source(config_path)
step1 <- run_spatial_join(spatial_config)
