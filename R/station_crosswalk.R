# Build explicit OD-code aliases using LTA's official code/name reference.
station_name_for_join <- function(x) {
  sub(" (MRT|LRT) STATION$", "", normalise_station_key(x))
}

build_station_crosswalk <- function(reference, exit_names, observed_codes) {
  require_columns(reference, c("stn_code", "mrt_station_english"), "LTA station reference")
  ref <- unique(data.frame(code = normalise_node_code(reference$stn_code, "train"),
    name = normalise_station_key(reference$mrt_station_english)))
  if (anyNA(ref$code) || anyNA(ref$name) || anyDuplicated(ref$code)) stop("Invalid/ambiguous official station codes")
  keys <- unique(normalise_station_key(exit_names))
  short <- station_name_for_join(keys)
  if (anyNA(short)) stop("Exit station names are missing")
  codes <- unique(c(ref$code, normalise_node_code(observed_codes, "train")))
  codes <- codes[!is.na(codes)]
  rows <- lapply(codes, function(code) {
    tokens <- strsplit(code, "/", fixed = TRUE)[[1]]
    ii <- match(tokens, ref$code)
    names_found <- unique(ref$name[ii])
    status <- if (anyNA(ii)) "code_missing_from_reference"
      else if (length(names_found) != 1L) "composite_spans_station_names" else "matched"
    station <- if (status == "matched") names_found[1] else NA_character_
    key <- NA_character_
    source_keys <- NA_character_
    if (status == "matched") {
      # Preserve MRT vs LRT stations with the same name as separate exit groups.
      is_lrt <- grepl("^(BP|SE|SW|PE|PW)[0-9]+$", tokens) | tokens %in% c("STC", "PTC")
      expected <- unique(paste(station, ifelse(is_lrt, "LRT STATION", "MRT STATION")))
      candidates <- intersect(expected, keys)
      if (!length(candidates)) candidates <- keys[short == station]
      if (length(candidates) && all(expected %in% keys)) {
        source_keys <- paste(sort(candidates), collapse = ";")
        key <- paste(sort(candidates), collapse = " + ")
      } else if (length(candidates) == 1L) {
        key <- candidates
        source_keys <- key
      } else status <- if (length(candidates)) "ambiguous_mrt_lrt_exit_groups" else "station_name_missing_from_exits"
    }
    data.frame(station_code = code, official_station_name = station, station_key = key,
      source_station_keys = source_keys,
      alignment_status = status, observed_in_od = code %in% normalise_node_code(observed_codes, "train"))
  })
  audit <- do.call(rbind, rows)
  list(crosswalk = audit[audit$alignment_status == "matched", c("station_key", "station_code", "source_station_keys")], audit = audit)
}

# Incremental code inventory: scan each changed monthly file once. No trips are
# loaded into the inventory. Cache identity includes absolute path, size, mtime.
build_od_inventory <- function(files, cache_path) {
  cache <- if (file.exists(cache_path)) readRDS(cache_path) else list()
  inventory <- list()
  for (i in seq_along(files)) {
    path <- normalizePath(files[i], winslash = "/", mustWork = TRUE)
    info <- file.info(path)
    stamp <- paste(info$size, as.numeric(info$mtime), sep = ":")
    cached <- cache[[path]]
    if (is.null(cached) || !identical(cached$stamp, stamp)) {
      message(sprintf("[%s/%s] Scanning %s", i, length(files), basename(path)))
      cached <- list(stamp = stamp, codes = read_od_codes(path))
      cache[[path]] <- cached
      dir.create(dirname(cache_path), recursive = TRUE, showWarnings = FALSE)
      saveRDS(cache, cache_path)
    }
    inventory[[i]] <- cached$codes
  }
  if (!length(inventory)) stop("No OD files found")
  unique(do.call(rbind, inventory))
}
