# Configured for the supplied LTA/URA GeoJSON files. Run from repo root.
# Verify that the polygon source is MASTER PLAN 2019 SUBZONE BOUNDARY.
spatial_dir <- Sys.getenv("AR5302_SPATIAL_DIR", "data/raw/spatial")
od_dir <- Sys.getenv("AR5302_OD_DIR", "data/raw/OD")
spatial_config <- list(
  subzones = list(path = file.path(spatial_dir, "MasterPlan2019SubzoneBoundaryNoSeaGEOJSON.geojson"), layer = NULL,
                  code = "SUBZONE_C", name = "SUBZONE_N"),
  mrt = list(path = file.path(spatial_dir, "LTAMRTStationExitGEOJSON.geojson"), layer = NULL,
             key = "STATION_NA"),
  bus = list(path = file.path(spatial_dir, "LTABusStop.geojson"), layer = NULL,
             key = "BUS_STOP_NUM"),
  # CSV points also work: list(path = "...csv", key = "BusStopCode",
  #   x = "Longitude", y = "Latitude", crs = 4326)
  # Spatial files use their own CRS metadata; no assumption based on filename.
  crosswalk = file.path(spatial_dir, "station_code_crosswalk.csv"),
  overrides = NULL, # optional CSV: mode,node_code,subzone_code,reason
  od_files = list.files(od_dir, full.names = TRUE,
    pattern = "^origin_destination_(train|bus)_[0-9]{6}\\.csv$"),
  od_inventory = NULL, # alternative small CSV with mode,pt_code (both endpoints)
  output_dir = "data/processed/spatial_join",
  require_od_coverage = TRUE,
  strict = TRUE # diagnostics still exported before unresolved cases stop the run
)
