# Save figures/tables in the analysis Rmds, embed them in the report
# =============================================================================
# The analysis Rmds (scripts/) do the heavy work and SAVE their results:
#   figures -> outputs/figures/<name>.png   (save_fig)
#   tables  -> outputs/tables/<name>.rds    (save_tab; small summary tables)
# The report (docs/report/report.Rmd) only READS these files (show_fig,
# show_tab), so it knits in seconds and does not need the raw OD data.
#
#   In an analysis Rmd:
#     source(here::here("R", "save_fig.R"))
#     save_fig(p, "bus_overlap_am_peak", width = 9, height = 5)
#     save_tab(metrics_table, "bus_indicator_means")
#
#   In the report:
#     ```{r fig.cap = "Figure 1. ..."}
#     show_fig("study_area_map")
#     ```
#
# Tables are saved as .rds (not .csv) because .gitignore blocks *.csv.
# =============================================================================

fig_dir <- here::here("outputs", "figures")
tab_dir <- here::here("outputs", "tables")

# save_fig(): write a ggplot / patchwork to outputs/figures/<name>.png
save_fig <- function(plot, name, width = 9, height = 6, dpi = 300) {
  stopifnot(is.character(name), length(name) == 1, !grepl("[ /\\\\]", name))
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(fig_dir, paste0(name, ".png"))
  ggplot2::ggsave(path, plot = plot, width = width, height = height,
                  dpi = dpi, bg = "white")
  message("Saved ", path)
  invisible(path)
}

# save_tab(): write a small data frame to outputs/tables/<name>.rds
save_tab <- function(data, name) {
  stopifnot(is.data.frame(data), is.character(name), length(name) == 1)
  if (inherits(data, "sf")) data <- sf::st_drop_geometry(data)  # keep files small
  dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(tab_dir, paste0(name, ".rds"))
  saveRDS(data, path)
  message("Saved ", path)
  invisible(path)
}

# Note printed in the report when a file has not been produced yet
missing_note <- function(file) {
  knitr::asis_output(sprintf(
    "\n\n**[Missing: `%s`. Run the analysis Rmd that makes it.]**\n\n", file))
}

# show_fig(): embed a saved figure (or a note if it does not exist yet)
show_fig <- function(name) {
  path <- file.path(fig_dir, paste0(name, ".png"))
  if (file.exists(path)) knitr::include_graphics(path, rel_path = FALSE)
  else missing_note(paste0("outputs/figures/", name, ".png"))
}

# read_tab(): read a saved table, or NULL if it does not exist yet
read_tab <- function(name) {
  path <- file.path(tab_dir, paste0(name, ".rds"))
  if (file.exists(path)) readRDS(path) else NULL
}
