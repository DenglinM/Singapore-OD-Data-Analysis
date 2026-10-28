# Read LTA DataMall monthly origin-destination (OD) files.
#
# The raw CSVs are large (bus: ~200 MB per month, ~18 GB in total), so they
# are converted once into a Parquet dataset under data/processed/ and then
# queried lazily with arrow + dplyr. Only the rows you filter are loaded into
# memory, when you call collect().
#
# Usage (in a script or Rmd):
#   source(here::here("R", "od_io.R"))
#   build_od_parquet()                      # one-off; skips months already done
#   od <- open_od()
#   od |> filter(MODE == "train", YYYYMM == 202001) |> collect()

od_raw_dir     <- here::here("data", "raw", "OD")
od_parquet_dir <- here::here("data", "processed", "od_parquet")

# Columns kept from each monthly file
od_cols <- c(
  "YEAR_MONTH", "DAY_TYPE", "TIME_PER_HOUR",
  "ORIGIN_PT_CODE", "DESTINATION_PT_CODE", "TOTAL_TRIPS"
)

# Bus stop codes look numeric but have leading zeros ("01012"). Read them as
# text, otherwise arrow turns them into integers (1012) and they no longer
# match the bus stop codes in the spatial data.
od_col_types <- arrow::schema(
  ORIGIN_PT_CODE      = arrow::utf8(),
  DESTINATION_PT_CODE = arrow::utf8()
)

# Read one monthly OD CSV, e.g. read_od_month("bus", "202001").
# Returns an Arrow Table; pipe it into collect() or as.data.frame() for a tibble.
read_od_month <- function(mode, yyyymm, raw_dir = od_raw_dir) {
  mode <- match.arg(mode, c("train", "bus"))
  path <- file.path(raw_dir, sprintf("origin_destination_%s_%s.csv", mode, yyyymm))
  if (!file.exists(path)) stop("OD file not found: ", path, call. = FALSE)

  arrow::read_csv_arrow(
    path,
    col_select    = tidyselect::all_of(od_cols),
    col_types     = od_col_types,
    as_data_frame = FALSE
  )
}

# Convert every origin_destination_<mode>_<YYYYMM>.csv in raw_dir into
# out_dir/MODE=<mode>/YYYYMM=<YYYYMM>/part-0.parquet.
# Months that already exist are skipped unless overwrite = TRUE, so this is
# cheap to re-run after downloading new months.
build_od_parquet <- function(raw_dir = od_raw_dir, out_dir = od_parquet_dir,
                             overwrite = FALSE) {
  files <- list.files(raw_dir, pattern = "^origin_destination_(train|bus)_[0-9]{6}\\.csv$")
  if (length(files) == 0) stop("No OD CSV files found in ", raw_dir, call. = FALSE)

  mode   <- sub("^origin_destination_(train|bus)_.*$", "\\1", files)
  yyyymm <- sub("^.*_([0-9]{6})\\.csv$", "\\1", files)

  for (i in seq_along(files)) {
    target_dir <- file.path(out_dir, paste0("MODE=", mode[i]), paste0("YYYYMM=", yyyymm[i]))
    target     <- file.path(target_dir, "part-0.parquet")
    if (file.exists(target) && !overwrite) next

    message("Converting ", files[i])
    dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
    arrow::write_parquet(read_od_month(mode[i], yyyymm[i], raw_dir), target)
  }

  invisible(out_dir)
}

# Open the Parquet dataset lazily. MODE ("train"/"bus") and YYYYMM (integer,
# e.g. 202001) come from the folder names and can be used in filter().
open_od <- function(out_dir = od_parquet_dir) {
  if (!dir.exists(out_dir)) {
    stop("No Parquet dataset at ", out_dir, ". Run build_od_parquet() first.", call. = FALSE)
  }
  arrow::open_dataset(out_dir)
}
