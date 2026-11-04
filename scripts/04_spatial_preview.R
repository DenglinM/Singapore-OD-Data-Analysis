# Run the spatial part before the MRT code crosswalk / OD inventory is ready.
# This intentionally allows unresolved cases and does NOT certify OD coverage.
source("R/spatial_join.R")
source(Sys.getenv("AR5302_SPATIAL_CONFIG", "config/spatial_join.R"))
spatial_config$od_files <- character()
spatial_config$od_inventory <- NULL
spatial_config$require_od_coverage <- FALSE
spatial_config$strict <- FALSE
step1_preview <- run_spatial_join(spatial_config)
