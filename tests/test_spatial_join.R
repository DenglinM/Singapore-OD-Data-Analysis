# Run from the repo root: Rscript tests/test_spatial_join.R
# Synthetic fixtures only. No real ridership or downloaded spatial data.
source("R/spatial_join.R")
library(sf)
rect <- function(x0, x1) st_polygon(list(matrix(c(x0, 0, x1, 0, x1, 10, x0, 10, x0, 0), ncol = 2, byrow = TRUE)))
zones <- prepare_subzones(st_sf(code = c("A", "B"), name = c("Alpha", "Beta"),
  geometry = st_sfc(rect(0, 10), rect(10, 20), crs = 3414)), "code", "name")
pts <- function(x, y = rep(5, length(x))) st_as_sf(data.frame(x = x, y = y), coords = c("x", "y"), crs = 3414)
expect_error <- function(expr) stopifnot(inherits(tryCatch({force(expr); NULL}, error = identity), "error"))
stopifnot(identical(normalise_node_code(c(" ew24 / ns1 ", "NS1/EW24", NA, ""), "train"),
                    c("EW24/NS1", "EW24/NS1", NA_character_, NA_character_)))
stopifnot(identical(normalise_node_code(c("1012", "01012", "BAD", NA), "bus"),
                    c("01012", "01012", NA_character_, NA_character_)))
# Two same-zone exits; duplicate; cross-zone exits; boundary; outside; empty.
p <- pts(c(2, 3, 3, 4, 14, 10, 30, 6))
st_geometry(p)[[8]] <- st_point()
b <- build_lookup(p, c("SAME", "SAME", "SAME", "SPLIT", "SPLIT", "EDGE", "OUT", "EMPTY"), zones, "train")
status <- setNames(b$lookup$match_status, b$lookup$node_id)
stopifnot(status["SAME"] == "matched", status["SPLIT"] == "multiple_subzones",
          status["EDGE"] == "ambiguous_point", status["OUT"] == "unmatched_point",
          status["EMPTY"] == "invalid_geometry", nrow(b$duplicates) == 1L,
          sum(b$point_matches$node_id == "EDGE") == 2L)
# Transform lon/lat input back before matching.
transformed <- match_points(st_transform(pts(2), 4326), zones)
stopifnot(transformed$subzone_code == "A")
expect_error(build_lookup(pts(2), NA_character_, zones, "train"))
bus <- build_lookup(pts(c(2, 3)), c("01012", "01012"), zones, "bus")
stopifnot(bus$lookup$match_status == "conflicting_stop_locations")
cw <- data.frame(station_key = c("same", "SAME", "MISSING"), station_code = c("NS1", "EW24/NS1", "ZZ9"))
mrt <- align_stations(b$lookup, cw)
stopifnot(nrow(mrt) == 3L, mrt$match_status[3] == "station_key_not_found")
expect_error(align_stations(b$lookup, data.frame(station_key = c("SAME", "SPLIT"), station_code = c("NS1", "NS1"))))
ov <- data.frame(mode = "train", node_code = "ZZ9", subzone_code = "B", reason = "Synthetic reviewed location")
mrt <- finish_lookup(apply_overrides(mrt, ov, "train", "station_code", zones), "station_code", zones)
stopifnot(all(mrt$join_ready), mrt$match_status[mrt$station_code == "ZZ9"] == "manual_override")
ov$subzone_code <- "NO_SUCH_ZONE"
expect_error(apply_overrides(mrt, ov, "train", "station_code", zones))

# Integration: actual input readers, chunked OD scan, strict mode, and exports.
tmp <- tempfile("ar5302_step1_")
dir.create(tmp)
st_write(zones, file.path(tmp, "zones.gpkg"), quiet = TRUE)
exits <- pts(c(2, 3, 14)); exits$STN_NAME <- c("ONE", "ONE", "TWO")
st_write(exits, file.path(tmp, "exits.gpkg"), quiet = TRUE)
readr::write_csv(data.frame(BusStopCode = c("01012", "02022"), x = c(2, 12), y = 5), file.path(tmp, "bus.csv"))
readr::write_csv(data.frame(station_key = c("ONE", "TWO"), station_code = c("NS1/EW24", "NS2")), file.path(tmp, "cw.csv"))
train_file <- file.path(tmp, "origin_destination_train_202001.csv")
bus_file <- file.path(tmp, "origin_destination_bus_202001.csv")
readr::write_csv(data.frame(ORIGIN_PT_CODE = "NS1/EW24", DESTINATION_PT_CODE = "NS2", TOTAL_TRIPS = 99), train_file)
readr::write_csv(data.frame(ORIGIN_PT_CODE = "01012", DESTINATION_PT_CODE = "02022", TOTAL_TRIPS = 99), bus_file)
cfg <- list(subzones = list(path = file.path(tmp, "zones.gpkg"), code = "subzone_code", name = "subzone_name"),
  mrt = list(path = file.path(tmp, "exits.gpkg"), key = "STN_NAME"),
  bus = list(path = file.path(tmp, "bus.csv"), key = "BusStopCode", x = "x", y = "y", crs = 3414),
  crosswalk = file.path(tmp, "cw.csv"), overrides = NULL, od_files = c(train_file, bus_file),
  od_inventory = NULL, output_dir = file.path(tmp, "out"), strict = TRUE, require_od_coverage = TRUE)
r <- run_spatial_join(cfg)
stopifnot(nrow(r$mrt) == 2L, nrow(r$bus) == 2L, all(r$coverage$coverage_status == "matched"),
  "01012" %in% read_text_csv(file.path(cfg$output_dir, "bus_stop_subzone_lookup.csv"))$bus_stop_code)
# Join both endpoints; no multiplication of trips or OD rows.
od <- data.frame(origin = c("NS1/EW24", "NS2"), destination = c("NS2", "EW24/NS1"), trips = c(8, 9))
od$origin_zone <- r$mrt$subzone_code[match(normalise_node_code(od$origin, "train"), r$mrt$station_code)]
od$destination_zone <- r$mrt$subzone_code[match(normalise_node_code(od$destination, "train"), r$mrt$station_code)]
stopifnot(nrow(od) == 2L, sum(od$trips) == 17, all(!is.na(od$origin_zone)), all(!is.na(od$destination_zone)))
readr::write_csv(data.frame(ORIGIN_PT_CODE = "MISSING", DESTINATION_PT_CODE = "NS2"), train_file)
expect_error(run_spatial_join(cfg))
stopifnot(file.exists(file.path(cfg$output_dir, "od_code_coverage.csv")))
cfg$od_files <- character()
expect_error(suppressWarnings(run_spatial_join(cfg)))
cfg$strict <- FALSE
unchecked <- suppressWarnings(run_spatial_join(cfg))
stopifnot(nrow(unchecked$coverage) == 0L, file.exists(file.path(cfg$output_dir, "validation_summary.csv")))
cat("All STEP 1 spatial join tests passed.\n")
