# STEP 1: conservative point-to-2019-subzone lookup construction.
# Dependencies: sf, readr. Source from the project root.
normalise_station_key <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x <- gsub("[[:space:]]+", " ", x)
  x[x == ""] <- NA_character_
  x
}

# Only slash-separated interchange codes are reordered. No fuzzy matching,
# substring matching, or inferred links between station names and codes.
normalise_node_code <- function(x, mode) {
  x <- toupper(trimws(as.character(x)))
  x[x == ""] <- NA_character_
  if (mode == "train") {
    x <- vapply(strsplit(x, "/", fixed = TRUE), function(z) {
      if (anyNA(z) || !length(z)) return(NA_character_)
      paste(sort(unique(trimws(z))), collapse = "/")
    }, character(1))
  } else if (mode == "bus") {
    ok <- !is.na(x) & grepl("^[0-9]{1,5}$", x)
    x[ok] <- sprintf("%05d", as.integer(x[ok]))
    x[!ok] <- NA_character_
  } else stop("mode must be train or bus")
  unname(x)
}

require_columns <- function(x, cols, label) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) stop(label, " missing columns: ", paste(missing, collapse = ", "))
}

read_text_csv <- function(path) {
  as.data.frame(readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                              show_col_types = FALSE, progress = FALSE))
}

read_spatial_input <- function(spec, point = FALSE) {
  if (!file.exists(spec$path)) stop("Missing input: ", spec$path)
  if (tolower(tools::file_ext(spec$path)) == "csv") {
    if (!point) stop("Subzones must be a polygon spatial file")
    x <- read_text_csv(spec$path)
    require_columns(x, c(spec$x, spec$y), spec$path)
    if (is.null(spec$crs)) stop("CSV coordinates require an explicit CRS")
    a <- suppressWarnings(as.numeric(x[[spec$x]]))
    b <- suppressWarnings(as.numeric(x[[spec$y]]))
    if (identical(as.integer(spec$crs), 4326L) &&
        any(is.finite(a) & is.finite(b) & (abs(a) > 180 | abs(b) > 90))) {
      stop("Coordinates outside longitude/latitude range; check x, y and CRS")
    }
    geom <- lapply(seq_len(nrow(x)), function(i) {
      if (!is.finite(a[i]) || !is.finite(b[i])) sf::st_point()
      else sf::st_point(c(a[i], b[i]))
    })
    x <- sf::st_sf(x, geometry = sf::st_sfc(geom, crs = spec$crs))
  } else {
    args <- list(dsn = spec$path, quiet = TRUE, stringsAsFactors = FALSE)
    if (!is.null(spec$layer)) args$layer <- spec$layer
    x <- do.call(sf::st_read, args)
  }
  if (!nrow(x)) stop("Empty input: ", spec$path)
  if (is.na(sf::st_crs(x))) stop("Unknown CRS: ", spec$path, "; define it from source metadata")
  if (point && any(!sf::st_geometry_type(x) %in% "POINT")) {
    stop("Expected POINT geometries: ", spec$path, "; do not substitute polygon centroids for exits")
  }
  sf::st_transform(x, 3414)
}

prepare_subzones <- function(x, code_col, name_col) {
  require_columns(x, c(code_col, name_col), "2019 subzones")
  if (is.na(sf::st_crs(x))) stop("Subzones have no CRS")
  x <- sf::st_transform(x, 3414)
  if (any(!sf::st_geometry_type(x) %in% c("POLYGON", "MULTIPOLYGON"))) {
    stop("Subzones must contain only polygons")
  }
  x <- sf::st_make_valid(x)
  if (any(sf::st_is_empty(x))) stop("Empty subzone geometry")
  out <- sf::st_sf(subzone_code = trimws(as.character(x[[code_col]])),
                   subzone_name = as.character(x[[name_col]]), geometry = sf::st_geometry(x))
  if (anyNA(out$subzone_code) || any(out$subzone_code == "") || anyDuplicated(out$subzone_code)) {
    stop("Subzone codes must be present and unique; dissolve multipart rows by code first")
  }
  out
}

# Retain every hit so boundary/overlap ambiguity is visible rather than taking
# the first polygon returned by st_join(). No nearest-polygon fallback.
match_points <- function(points, zones) {
  if (is.na(sf::st_crs(points))) stop("Points have no CRS")
  points <- sf::st_transform(points, 3414)
  valid <- !sf::st_is_empty(points) & sf::st_is_valid(points)
  hits <- vector("list", nrow(points))
  hits[valid] <- sf::st_intersects(points[valid, ], zones)
  n <- lengths(hits)
  idx <- rep(seq_len(nrow(points)), pmax(n, 1L))
  zi <- unlist(lapply(hits, function(h) if (length(h)) h else NA_integer_), use.names = FALSE)
  detail <- data.frame(point_row = idx, subzone_code = zones$subzone_code[zi],
                       subzone_name = zones$subzone_name[zi], stringsAsFactors = FALSE)
  detail$point_status <- ifelse(!valid[idx], "invalid_geometry",
                                ifelse(n[idx] == 0L, "unmatched", ifelse(n[idx] > 1L, "ambiguous", "matched")))
  detail
}

build_lookup <- function(points, id, zones, mode) {
  if (length(id) != nrow(points) || anyNA(id) || any(id == "")) stop("Missing point identifiers")
  # Duplicate records at precisely the same location do not get extra votes.
  wkt <- sf::st_as_text(sf::st_geometry(points))
  keep <- !duplicated(data.frame(id = id, wkt = wkt))
  duplicate_rows <- data.frame(source_row = which(!keep), node_id = id[!keep])
  source_row <- which(keep)
  id <- id[keep]
  points <- points[keep, ]
  detail <- match_points(points, zones)
  detail$node_id <- id[detail$point_row]
  detail$source_row <- source_row[detail$point_row]
  rows <- lapply(unique(id), function(key) {
    d <- detail[detail$node_id == key, ]
    all_ok <- all(d$point_status == "matched")
    codes <- unique(d$subzone_code[!is.na(d$subzone_code)])
    np <- length(unique(d$point_row))
    status <- if (mode == "bus" && np > 1L) "conflicting_stop_locations"
      else if (any(d$point_status == "invalid_geometry")) "invalid_geometry"
      else if (any(d$point_status == "ambiguous")) "ambiguous_point"
      else if (!all_ok) "unmatched_point"
      else if (length(codes) > 1L) "multiple_subzones"
      else "matched"
    data.frame(node_id = key, subzone_code = if (status == "matched") codes[1] else NA_character_,
               match_status = status, n_points = np, n_candidate_subzones = length(codes),
               candidate_subzones = paste(sort(codes), collapse = ";"), stringsAsFactors = FALSE)
  })
  list(lookup = do.call(rbind, rows), point_matches = detail, duplicates = duplicate_rows)
}

align_stations <- function(stations, crosswalk) {
  require_columns(crosswalk, c("station_key", "station_code"), "station crosswalk")
  crosswalk$station_key <- normalise_station_key(crosswalk$station_key)
  crosswalk$station_code <- normalise_node_code(crosswalk$station_code, "train")
  if (anyNA(crosswalk$station_key) || anyNA(crosswalk$station_code)) stop("Blank crosswalk keys/codes")
  crosswalk <- unique(crosswalk[c("station_key", "station_code")])
  if (anyDuplicated(crosswalk$station_code)) stop("A station code maps to multiple station keys")
  idx <- match(crosswalk$station_key, stations$node_id)
  out <- stations[idx, , drop = FALSE]
  out$station_key <- crosswalk$station_key
  out$station_code <- crosswalk$station_code
  out$node_id <- NULL
  out$match_status[is.na(idx)] <- "station_key_not_found"
  rownames(out) <- NULL
  out
}

apply_overrides <- function(lookup, overrides, mode, key_col, zones) {
  if (!nrow(overrides)) return(lookup)
  require_columns(overrides, c("mode", "node_code", "subzone_code", "reason"), "overrides")
  o <- overrides[overrides$mode == mode, , drop = FALSE]
  if (!nrow(o)) return(lookup)
  o$node_code <- normalise_node_code(o$node_code, mode)
  if (anyNA(o$node_code) || anyDuplicated(o$node_code) ||
      anyNA(o$reason) || any(trimws(o$reason) == "") ||
      anyNA(o$subzone_code) || any(!o$subzone_code %in% zones$subzone_code)) stop("Invalid overrides for ", mode)
  ix <- match(o$node_code, lookup[[key_col]])
  if (anyNA(ix)) stop("Override keys not in lookup for ", mode)
  lookup$override_reason <- NA_character_
  lookup$override_reason[ix] <- o$reason
  lookup$subzone_code[ix] <- o$subzone_code
  lookup$match_status[ix] <- "manual_override"
  lookup
}

finish_lookup <- function(x, key_col, zones) {
  if (anyNA(x[[key_col]]) || anyDuplicated(x[[key_col]])) stop("Lookup keys must be unique and present")
  x$subzone_name <- zones$subzone_name[match(x$subzone_code, zones$subzone_code)]
  x$boundary_year <- rep(2019L, nrow(x))
  x$join_ready <- !is.na(x$subzone_code)
  x[order(x[[key_col]]), , drop = FALSE]
}

# Chunked scan reads only the two code columns, not the full OD table.
read_od_codes <- function(files, inventory_path = NULL) {
  result <- data.frame(mode = character(), pt_code = character())
  if (!is.null(inventory_path)) {
    result <- read_text_csv(inventory_path)
    require_columns(result, c("mode", "pt_code"), "OD code inventory")
    result <- result[c("mode", "pt_code")]
  }
  for (path in files) {
    mode <- if (grepl("origin_destination_train_", basename(path))) "train"
      else if (grepl("origin_destination_bus_", basename(path))) "bus" else stop("Unknown OD filename: ", path)
    codes <- character()
    cb <- readr::SideEffectChunkCallback$new(function(x, pos) {
      require_columns(x, c("ORIGIN_PT_CODE", "DESTINATION_PT_CODE"), path)
      codes <<- unique(c(codes, x$ORIGIN_PT_CODE, x$DESTINATION_PT_CODE))
    })
    readr::read_csv_chunked(path, callback = cb, chunk_size = 250000L,
      col_types = readr::cols_only(ORIGIN_PT_CODE = readr::col_character(),
                                  DESTINATION_PT_CODE = readr::col_character()), progress = FALSE)
    result <- rbind(result, data.frame(mode = mode, pt_code = codes))
  }
  if (anyNA(result$mode) || any(!result$mode %in% c("train", "bus"))) stop("Invalid OD inventory mode")
  unique(result)
}

check_od_coverage <- function(codes, mrt, bus) {
  codes$normalised_code <- rep(NA_character_, nrow(codes))
  codes$coverage_status <- rep(NA_character_, nrow(codes))
  for (m in c("train", "bus")) {
    i <- which(codes$mode == m)
    lookup <- if (m == "train") mrt else bus
    key <- if (m == "train") "station_code" else "bus_stop_code"
    codes$normalised_code[i] <- normalise_node_code(codes$pt_code[i], m)
    j <- match(codes$normalised_code[i], lookup[[key]])
    codes$coverage_status[i] <- ifelse(is.na(j), "code_not_in_lookup",
                                      ifelse(lookup$join_ready[j], "matched", "unresolved_subzone"))
    codes$coverage_status[i[is.na(codes$normalised_code[i])]] <- "invalid_code"
  }
  codes
}

run_spatial_join <- function(config) {
  zones <- prepare_subzones(read_spatial_input(config$subzones), config$subzones$code, config$subzones$name)
  exits <- read_spatial_input(config$mrt, point = TRUE)
  stops <- read_spatial_input(config$bus, point = TRUE)
  require_columns(exits, config$mrt$key, "MRT exits")
  require_columns(stops, config$bus$key, "bus stops")
  mr <- build_lookup(exits, normalise_station_key(exits[[config$mrt$key]]), zones, "train")
  bu <- build_lookup(stops, normalise_node_code(stops[[config$bus$key]], "bus"), zones, "bus")
  crosswalk_available <- !is.null(config$crosswalk) && file.exists(config$crosswalk)
  crosswalk <- if (crosswalk_available) read_text_csv(config$crosswalk) else
    data.frame(station_key = character(), station_code = character())
  mrt <- align_stations(mr$lookup, crosswalk)
  bus <- bu$lookup
  names(bus)[names(bus) == "node_id"] <- "bus_stop_code"
  overrides <- if (!is.null(config$overrides)) read_text_csv(config$overrides) else data.frame()
  if (nrow(overrides) && anyNA(match(overrides$mode, c("train", "bus")))) stop("Invalid override mode")
  mrt <- finish_lookup(apply_overrides(mrt, overrides, "train", "station_code", zones), "station_code", zones)
  bus <- finish_lookup(apply_overrides(bus, overrides, "bus", "bus_stop_code", zones), "bus_stop_code", zones)
  unaligned <- mr$lookup[!mr$lookup$node_id %in% normalise_station_key(crosswalk$station_key), , drop = FALSE]
  codes <- read_od_codes(config$od_files, config$od_inventory)
  coverage <- check_od_coverage(codes, mrt, bus)
  dir.create(config$output_dir, recursive = TRUE, showWarnings = FALSE)
  write <- function(x, name) readr::write_csv(x, file.path(config$output_dir, paste0(name, ".csv")), na = "")
  write(mrt, "mrt_station_subzone_lookup")
  write(bus, "bus_stop_subzone_lookup")
  by_name <- mr$lookup
  names(by_name)[names(by_name) == "node_id"] <- "station_key"
  by_name <- finish_lookup(by_name, "station_key", zones)
  write(by_name, "mrt_station_name_subzone_lookup")
  write(by_name[!by_name$join_ready, , drop = FALSE], "mrt_station_names_unresolved")
  write(data.frame(station_key = mr$lookup$node_id, station_code = ""), "station_code_crosswalk_template")
  write(mr$point_matches, "mrt_exit_matches")
  write(bu$point_matches, "bus_point_matches")
  write(mr$duplicates, "mrt_duplicate_points")
  write(bu$duplicates, "bus_duplicate_points")
  write(unaligned, "mrt_keys_without_codes")
  write(mrt[!mrt$join_ready, , drop = FALSE], "mrt_unresolved")
  write(bus[!bus$join_ready, , drop = FALSE], "bus_unresolved")
  write(coverage, "od_code_coverage")
  summary <- data.frame(check = c("mrt_station_names", "mrt_station_names_unresolved", "mrt_codes", "bus_codes", "mrt_unresolved", "bus_unresolved",
    "mrt_keys_without_codes", "od_codes_checked", "od_codes_unresolved"),
    count = c(nrow(by_name), sum(!by_name$join_ready), nrow(mrt), nrow(bus), sum(!mrt$join_ready), sum(!bus$join_ready), nrow(unaligned),
              nrow(coverage), sum(coverage$coverage_status != "matched")))
  write(summary, "validation_summary")
  saveRDS(config, file.path(config$output_dir, "run_config.rds"))
  capture.output(utils::sessionInfo(), file = file.path(config$output_dir, "session_info.txt"))
  print(summary, row.names = FALSE)
  if (!crosswalk_available) warning("Station-code crosswalk missing: MRT spatial results by station name were exported; OD-ready MRT lookup has no rows. Fill the generated template and rerun.")
  if (!nrow(codes)) warning("OD coverage NOT CHECKED: supply raw OD CSVs or od_inventory")
  issues <- any(!mrt$join_ready) || any(!bus$join_ready) || nrow(unaligned) > 0L ||
    any(coverage$coverage_status != "matched") || (!nrow(codes) && isTRUE(config$require_od_coverage))
  if (issues && isTRUE(config$strict)) stop("STEP 1 needs review. Diagnostics were written to ", config$output_dir)
  invisible(list(mrt = mrt, bus = bus, coverage = coverage, summary = summary))
}
