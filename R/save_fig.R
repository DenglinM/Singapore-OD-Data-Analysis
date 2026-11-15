# Save and embed report figures
# =============================================================================
# The analysis Rmds do the heavy work and SAVE their figures as PNG files in
# outputs/figures/. The summary report (docs/report/report.Rmd) only EMBEDS
# those files, so it knits in seconds and does not need the raw OD data.
#
#   In an analysis Rmd:
#     source(here::here("R", "save_fig.R"))
#     p <- stylized_line(...)
#     save_fig(p, "fig02_train_attraction")      # -> outputs/figures/fig02_train_attraction.png
#
#   In the report:
#     ```{r fig.cap = "Caption text"}
#     show_fig("fig02_train_attraction")
#     ```
#
# File naming: figNN_<mode>_<topic>.png, all lower case, no spaces. NN is the
# planned position in the report (see outputs/figures/README.md), so names
# stay stable even when the analysis code moves around.
# =============================================================================

fig_dir <- here::here("outputs", "figures")

# Default sizes in inches (at 300 dpi). A4 text width is about 6.5 in.
fig_sizes <- list(
  wide   = c(width = 7,   height = 4),    # line charts, bar charts
  square = c(width = 6,   height = 6),    # matrices
  map    = c(width = 7,   height = 5),    # single Singapore map
  facet  = c(width = 7,   height = 7.5)   # multi-panel maps
)

# save_fig(): write a ggplot to outputs/figures/<name>.png and return the path
#   plot   a ggplot object (default: the last plot drawn)
#   name   file name without extension, e.g. "fig02_train_attraction"
#   size   one of names(fig_sizes), or give width / height directly
save_fig <- function(plot = ggplot2::last_plot(), name,
                     size = c("wide", "square", "map", "facet"),
                     width = NULL, height = NULL, dpi = 300) {
  size <- match.arg(size)
  stopifnot(is.character(name), length(name) == 1, !grepl("[ /\\\\]", name))
  dims <- fig_sizes[[size]]
  path <- file.path(fig_dir, paste0(name, ".png"))
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(path, plot = plot,
                  width  = width  %||% dims[["width"]],
                  height = height %||% dims[["height"]],
                  dpi = dpi, bg = "white")
  message("Saved ", path)
  invisible(path)
}

# show_fig(): embed a saved figure in an Rmd. If the file does not exist yet
# (the analysis that makes it has not been run), a short note is printed
# instead, so the report still knits while work is in progress.
show_fig <- function(name, dir = fig_dir) {
  path <- file.path(dir, paste0(name, ".png"))
  if (file.exists(path)) {
    knitr::include_graphics(path, rel_path = FALSE)
  } else {
    knitr::asis_output(sprintf(
      "\n\n> **Figure not available yet:** `%s.png`. Run the analysis Rmd that saves it (see `outputs/figures/README.md`).\n\n",
      name))
  }
}

if (!exists("%||%")) `%||%` <- function(a, b) if (is.null(a)) b else a
