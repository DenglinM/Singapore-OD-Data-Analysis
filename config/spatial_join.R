# Edit paths/field names to match your downloaded files. Run from repo root.
# Verify that the polygon source is MASTER PLAN 2019 SUBZONE BOUNDARY.
spatial_config <- list(
  subzones = list(path = "data/raw/spatial/MP2019_Subzone.gpkg", layer = NULL,
                  code = "SUBZONE_C", name = "SUBZONE_N"),
  mrt = list(path = "data/raw/spatial/TrainStationExitPoint.shp", layer = NULL,
             key = "STN_NAME"),
  bus = list(path = "data/raw/spatial/BusStop.shp", layer = NULL,
             key = "BUS_STOP_N"),
  # CSV points also work: list(path = "...csv", key = "BusStopCode",
  #   x = "Longitude", y = "Latitude", crs = 4326)
  # Spatial files use their own CRS metadata; no assumption based on filename.
  crosswalk = "data/raw/spatial/station_code_crosswalk.csv",
  overrides = NULL, # optional CSV: mode,node_code,subzone_code,reason
  od_files = list.files("data/raw/OD", full.names = TRUE,
    pattern = "^origin_destination_(train|bus)_[0-9]{6}\\.csv$"),
  od_inventory = NULL, # alternative small CSV with mode,pt_code (both endpoints)
  output_dir = "data/processed/spatial_join",
  require_od_coverage = TRUE,
  strict = TRUE # diagnostics still exported before unresolved cases stop the run
)
