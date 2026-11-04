# Build a code/name crosswalk from LTA's official Excel and observed OD codes.
# Inputs: local LTA reference, MRT exit GeoJSON, monthly train/bus OD CSVs.
# Outputs: data/processed/spatial_join_inputs/ (never edits raw files).
source("R/spatial_join.R")
source("R/station_crosswalk.R")
source(Sys.getenv("AR5302_SPATIAL_CONFIG", "config/spatial_join.R"))
if (!requireNamespace("readxl", quietly = TRUE)) stop("Install readxl first")
reference_path <- Sys.getenv("AR5302_STATION_REFERENCE",
  "data/raw/reference/Train Station Codes and Chinese Names.xls")
reference <- as.data.frame(readxl::read_excel(reference_path, col_types = "text"))
source("config/station_reference_supplements.R")
reference <- unique(rbind(reference[c("stn_code", "mrt_station_english")],
  station_reference_supplements[c("stn_code", "mrt_station_english")]))
input_dir <- "data/processed/spatial_join_inputs"
dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)
files <- spatial_config$od_files
if (!length(files) && !is.null(spatial_config$od_inventory)) {
  # Default config switches to the generated inventory for the spatial join;
  # the builder refreshes the underlying monthly files instead.
  files <- list.files(Sys.getenv("AR5302_OD_DIR", "data/raw/OD"), full.names = TRUE,
    pattern = "^origin_destination_(train|bus)_[0-9]{6}\\.csv$")
}
inventory <- build_od_inventory(files, file.path(input_dir, "od_code_cache.rds"))
readr::write_csv(inventory, file.path(input_dir, "od_node_codes.csv"))
exits <- read_spatial_input(spatial_config$mrt, point = TRUE)
alignment <- build_station_crosswalk(reference, exits[[spatial_config$mrt$key]],
  inventory$pt_code[inventory$mode == "train"])
readr::write_csv(alignment$crosswalk, file.path(input_dir, "station_code_crosswalk.csv"))
readr::write_csv(alignment$audit, file.path(input_dir, "station_code_alignment_audit.csv"))
readr::write_csv(alignment$audit[alignment$audit$observed_in_od & alignment$audit$alignment_status != "matched", ],
  file.path(input_dir, "observed_mrt_codes_unaligned.csv"))
capture.output(list(reference = normalizePath(reference_path), md5 = tools::md5sum(reference_path),
  od_files = file.info(files)[c("size", "mtime")]),
  file = file.path(input_dir, "input_manifest.txt"))
print(table(alignment$audit$alignment_status, alignment$audit$observed_in_od))
message("Crosswalk and OD inventory exported. Run scripts/04_spatial_join.R next.")
