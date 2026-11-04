# Compact review files; uses the code-scan cache, never rescans large OD tables.
source("R/spatial_join.R")
source(Sys.getenv("AR5302_SPATIAL_CONFIG", "config/spatial_join.R"))
out <- spatial_config$output_dir
coverage <- read_text_csv(file.path(out, "od_code_coverage.csv"))
bad <- coverage[coverage$coverage_status != "matched", ]
readr::write_csv(bad, file.path(out, "od_unresolved_codes.csv"), na = "")
audit <- read_text_csv("data/processed/spatial_join_inputs/station_code_alignment_audit.csv")
issues <- audit[audit$observed_in_od == "TRUE" & audit$alignment_status != "matched", ]
cache <- readRDS("data/processed/spatial_join_inputs/od_code_cache.rds")
files <- list.files(Sys.getenv("AR5302_OD_DIR", "data/raw/OD"),
  pattern = "^origin_destination_train_[0-9]{6}\\.csv$", full.names = TRUE)
rows <- list()
for (path in files) {
  key <- normalizePath(path, winslash = "/", mustWork = TRUE)
  cached <- cache[[key]]
  if (is.null(cached)) next
  c <- cached$codes
  c$normalised_code <- normalise_node_code(c$pt_code, "train")
  c <- c[c$normalised_code %in% issues$station_code, ]
  if (!nrow(c)) next
  c$yyyymm <- sub("^.*_([0-9]{6})\\.csv$", "\\1", basename(path))
  c$alignment_status <- issues$alignment_status[match(c$normalised_code, issues$station_code)]
  rows[[length(rows) + 1L]] <- c
}
by_month <- if (length(rows)) do.call(rbind, rows) else data.frame(
  mode=character(), pt_code=character(), normalised_code=character(), yyyymm=character(), alignment_status=character())
readr::write_csv(by_month, file.path(out, "mrt_code_issues_by_month.csv"), na = "")
print(table(coverage$mode, coverage$coverage_status))
