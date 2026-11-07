# Classify bus stops by URA urban-centre hierarchy (CBD, Central Area,
# regional / sub-regional / fringe centres).
#
# URA does not publish a list of bus stop codes per centre, and only the CBD
# and Central Area can be tied to official boundaries (Master Plan 2019
# planning areas). Regional, sub-regional and fringe centres have no official
# GIS boundary, so they are approximated by a walking-distance buffer around
# the MRT station that anchors each centre. See docs/urban_centres.md for the
# definitions and sources.
#
# Usage:
#   source(here::here("R", "urban_centres.R"))
#   stops <- classify_bus_stops()            # sf object, one row per bus stop
#   stops |> sf::st_drop_geometry() |> dplyr::count(zone_class)

library(sf)
library(dplyr)

spatial_dir <- here::here("data", "raw", "spatial")

# URA Central Area: the 11 planning areas of the city centre (MP2019).
central_area_pa <- c(
  "DOWNTOWN CORE", "MARINA EAST", "MARINA SOUTH", "MUSEUM", "NEWTON",
  "ORCHARD", "OUTRAM", "RIVER VALLEY", "ROCHOR", "SINGAPORE RIVER",
  "STRAITS VIEW"
)

# CBD: URA has no separate "CBD" polygon; the Downtown Core planning area
# (Raffles Place, Tanjong Pagar, Marina Centre, Bayfront, City Hall, Bugis ...)
# is used as the CBD.
cbd_pa <- "DOWNTOWN CORE"

# Centres named on URA's "Decentralisation" planning-strategy page.
# anchor_station must match STATION_NA in LTA's MRT Station Exit dataset.
# subzone lists the MP2019 subzone(s) whose name matches the centre, where
# one exists; it is only used for the sensitivity flag in_centre_subzone.
urban_centres <- tibble::tribble(
  ~centre_name,                 ~centre_type,          ~anchor_station,           ~subzone,
  "Woodlands Regional Centre",  "Regional centre",     "WOODLANDS MRT STATION",   "WOODLANDS REGIONAL CENTRE",
  "Jurong Lake District",       "Regional centre",     "JURONG EAST MRT STATION", "JURONG GATEWAY|LAKESIDE (BUSINESS)|LAKESIDE (LEISURE)",
  "Tampines Regional Centre",   "Regional centre",     "TAMPINES MRT STATION",    NA,
  "Bishan",                     "Sub-regional centre", "BISHAN MRT STATION",      "BISHAN EAST",
  "Serangoon",                  "Sub-regional centre", "SERANGOON MRT STATION",   "SERANGOON CENTRAL",
  "Paya Lebar",                 "Sub-regional centre", "PAYA LEBAR MRT STATION",  NA,
  "Newton",                     "Fringe centre",       "NEWTON MRT STATION",      "NEWTON CIRCUS",
  "Novena",                     "Fringe centre",       "NOVENA MRT STATION",      NA
)

# data.gov.sg GeoJSON files (converted from KML) store their attributes as an
# HTML table in a "Description" column. Pull one field out of that table.
kml_attr <- function(description, field) {
  pattern <- paste0("<th>", field, "</th>\\s*<td>(.*?)</td>")
  m <- regmatches(description, regexec(pattern, description))
  vapply(m, function(x) if (length(x) == 2) trimws(x[2]) else NA_character_, "")
}

# Return `field` from an sf object, whether it is a real column (shapefile)
# or hidden in the Description HTML (data.gov.sg GeoJSON).
get_attr <- function(x, field) {
  if (field %in% names(x)) return(as.character(x[[field]]))
  if ("Description" %in% names(x)) return(kml_attr(x$Description, field))
  stop("Field ", field, " not found", call. = FALSE)
}

find_file <- function(pattern, dir = spatial_dir) {
  f <- list.files(dir, pattern = pattern, recursive = TRUE, full.names = TRUE,
                  ignore.case = TRUE)
  if (length(f) == 0) stop("No file matching '", pattern, "' in ", dir, call. = FALSE)
  if (length(f) > 1) message("Several files match '", pattern, "'; using ", f[1])
  f[1]
}

# LTA DataMall static dataset "Bus Stop Location" (BusStop.shp, SVY21).
read_bus_stops <- function(path = find_file("^BusStop\\.shp$")) {
  st_read(path, quiet = TRUE) |>
    st_zm() |>
    st_transform(3414) |>
    transmute(
      # Bus stop codes have leading zeros ("01012"); keep them as 5-char text
      bus_stop_code = stringr::str_pad(as.character(BUS_STOP_N), 5, pad = "0"),
      loc_desc      = LOC_DESC
    ) |>
    distinct(bus_stop_code, .keep_all = TRUE)
}

# URA "Master Plan 2019 Subzone Boundary (No Sea)" GeoJSON from data.gov.sg.
read_subzones <- function(path = find_file("SubzoneBoundary.*\\.(geojson|shp)$")) {
  sz <- st_read(path, quiet = TRUE) |> st_zm()
  sz |>
    mutate(
      subzone       = get_attr(sz, "SUBZONE_N"),
      planning_area = get_attr(sz, "PLN_AREA_N"),
      region        = get_attr(sz, "REGION_N")
    ) |>
    select(subzone, planning_area, region) |>
    st_transform(3414) |>
    st_make_valid()
}

# LTA "MRT Station Exit" GeoJSON from data.gov.sg. One point per station:
# the centroid of all of its exits.
read_mrt_stations <- function(path = find_file("MRTStationExit.*\\.geojson$")) {
  ex <- st_read(path, quiet = TRUE) |> st_zm()
  ex |>
    mutate(station = get_attr(ex, "STATION_NA")) |>
    st_transform(3414) |>
    group_by(station) |>
    summarise(.groups = "drop") |>
    st_centroid()
}

# Main function. radius_m: walking-distance buffer around each centre's
# anchor MRT station (800 m ~ 10-minute walk, the usual station catchment).
classify_bus_stops <- function(radius_m = 800,
                               stops = read_bus_stops(),
                               subzones = read_subzones(),
                               stations = read_mrt_stations(),
                               centres = urban_centres) {
  idx <- match(centres$anchor_station, stations$station)
  missing <- centres$anchor_station[is.na(idx)]
  if (length(missing) > 0) stop("Anchor station not found: ", toString(missing), call. = FALSE)
  anchors <- st_sf(centres, geometry = st_geometry(stations)[idx])

  # 1. Planning area / subzone of each stop (stops in Johor Bahru get NA)
  out <- st_join(stops, subzones, join = st_intersects, left = TRUE) |>
    distinct(bus_stop_code, .keep_all = TRUE)

  # 2. Nearest centre and distance to its anchor station
  nearest <- st_nearest_feature(out, anchors)
  out$nearest_centre <- anchors$centre_name[nearest]
  out$dist_to_centre_m <- round(as.numeric(
    st_distance(out, anchors[nearest, ], by_element = TRUE)
  ), 1)

  in_buffer <- out$dist_to_centre_m <= radius_m
  out$centre_name <- ifelse(in_buffer, out$nearest_centre, NA_character_)
  out$centre_type <- centres$centre_type[match(out$centre_name, centres$centre_name)]

  # 3. Sensitivity flag: stop lies in a subzone named after the centre
  centre_subzones <- unlist(strsplit(na.omit(centres$subzone), "|", fixed = TRUE))
  out$in_centre_subzone <- out$subzone %in% centre_subzones

  # 4. Final class, highest level of the hierarchy wins
  out |>
    mutate(
      in_cbd          = planning_area %in% cbd_pa,
      in_central_area = planning_area %in% central_area_pa,
      zone_class = case_when(
        in_cbd               ~ "CBD",
        in_central_area      ~ "Central Area (non-CBD)",
        !is.na(centre_type)  ~ centre_type,
        is.na(planning_area) ~ "Outside Singapore",
        TRUE                 ~ "Other"
      ),
      zone_class = factor(zone_class, levels = c(
        "CBD", "Central Area (non-CBD)", "Regional centre",
        "Sub-regional centre", "Fringe centre", "Other", "Outside Singapore"
      ))
    ) |>
    select(bus_stop_code, loc_desc, zone_class, centre_name, centre_type,
           in_cbd, in_central_area, in_centre_subzone, nearest_centre,
           dist_to_centre_m, planning_area, subzone, region)
}
