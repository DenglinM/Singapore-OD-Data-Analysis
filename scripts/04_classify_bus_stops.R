# Author:  Denglin (with Claude)
# Purpose: Label every bus stop as CBD / Central Area / regional centre /
#          sub-regional centre / fringe centre / other, following URA's
#          urban-centre hierarchy. Definitions and sources: docs/urban_centres.md
# Inputs:  data/raw/spatial/  (see data/README.md)
#            - BusStopLocation_*/BusStop.shp                 (LTA DataMall)
#            - MasterPlan2019SubzoneBoundaryNoSeaGEOJSON.geojson (URA, data.gov.sg)
#            - LTAMRTStationExitGEOJSON.geojson               (LTA, data.gov.sg)
# Outputs: data/processed/bus_stop_centres.csv   one row per bus stop
#          data/processed/bus_stop_centres.gpkg  same, as points for QGIS
#          outputs/tables/bus_stop_centre_summary.csv

library(here)
library(dplyr)
library(sf)
source(here("R", "urban_centres.R"))

radius_m <- 800 # walking catchment around each centre's anchor MRT station

stops <- classify_bus_stops(radius_m = radius_m)

# Bus stop codes stay as text so they join with ORIGIN_PT_CODE /
# DESTINATION_PT_CODE in the OD data (see R/od_io.R).
readr::write_csv(st_drop_geometry(stops), here("data", "processed", "bus_stop_centres.csv"))
st_write(stops, here("data", "processed", "bus_stop_centres.gpkg"),
         layer = "bus_stop_centres", delete_dsn = TRUE, quiet = TRUE)

summary_tbl <- stops |>
  st_drop_geometry() |>
  count(zone_class, centre_name, name = "n_stops")
readr::write_csv(summary_tbl, here("outputs", "tables", "bus_stop_centre_summary.csv"))
print(summary_tbl, n = Inf)

# Example: tag bus OD flows with the class of their origin and destination
# source(here("R", "od_io.R"))
# lut <- st_drop_geometry(stops) |> select(bus_stop_code, zone_class)
# open_od() |>
#   filter(MODE == "bus", YYYYMM == 202409) |>
#   collect() |>
#   left_join(lut, by = c("ORIGIN_PT_CODE" = "bus_stop_code")) |>
#   left_join(lut, by = c("DESTINATION_PT_CODE" = "bus_stop_code"),
#             suffix = c("_origin", "_destination"))
