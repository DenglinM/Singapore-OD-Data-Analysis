# Shared map style for the group project
# ---------------------------------------------------------------
# source(here::here("R", "map_theme.R")) in any Rmd, then build a map as:
#   ggplot() + geom_sf(data = ..., aes(fill = ...)) + scale_fill_...() +
#     map_layers(st_bbox(<subzone layer in EPSG:3414>))
# Change colours, fonts, legend or frame HERE and every map follows.

library(ggplot2)
library(sf)

# ---- Colours and labels ------------------------------------------------------
shed_levels  <- c("Core", "Strong", "Weak", "Peripheral", "No flow")
# Same colour logic as the service-shed maps in Hou et al. (2025):
# red = core, orange = strong, yellow = weak, pale green = peripheral
shed_colours <- c("Core" = "#d7191c", "Strong" = "#fd8d3c", "Weak" = "#ffe34d",
                  "Peripheral" = "#cfe8c0", "No flow" = "white")
shed_labels  <- c("Core (0-25 %)", "Strong (25-50 %)", "Weak (50-75 %)",
                  "Peripheral (75-100 %)", "No flow")
mode_label   <- c(train = "MRT/LRT", bus = "Bus")

# ggspatial (scale bar, north arrow) is optional: maps still work without it
has_ggspatial <- requireNamespace("ggspatial", quietly = TRUE)

# MRT line names and official LTA line colours
mrt_line_names <- c(NS = "North South Line", EW = "East West Line",
                    NE = "North East Line",  CC = "Circle Line",
                    DT = "Downtown Line",    TE = "Thomson-East Coast Line")
# Official LTA line colours
mrt_line_colours <- c("North South Line" = "#D42E12", "East West Line" = "#009645",
                      "North East Line"  = "#9900AA", "Circle Line"    = "#FA9E0D",
                      "Downtown Line"    = "#005EC4", "Thomson-East Coast Line" = "#9D5B25")


# ---- Theme and layers shared by every map ------------------------------------
# Every map in the report uses map_layers(): same frame, lon/lat labels,
# north arrow and scale bar. Each map then only adds its own data + fill scale.
map_base_theme <- theme_bw(base_size = 11) +
  theme(
    panel.border  = element_blank(),
    panel.grid    = element_blank(),
    axis.title    = element_blank(),
    axis.text     = element_text(size = 8, colour = "black"),
    axis.ticks    = element_line(colour = "black", linewidth = 0.4),
    legend.title  = element_text(size = 9),
    legend.text   = element_text(size = 8),
    legend.position = "right",
    plot.title.position   = "plot",
    plot.caption.position = "plot",
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 9, colour = "grey25"),
    plot.caption  = element_text(size = 7.5, colour = "grey35", hjust = 0),
    strip.background = element_blank(),
    strip.text    = element_text(face = "bold", size = 11, hjust = 0),
    plot.margin   = margin(8, 8, 8, 8)
  )

# bb: st_bbox() of the subzone layer in EPSG:3414 (limits are in metres;
# axis labels are shown as longitude / latitude)
map_layers <- function(bb) {
  layers <- list(
    coord_sf(xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")],
             expand = FALSE, datum = st_crs(4326),
             label_axes = list(bottom = "E", left = "N"))
  )
  if (has_ggspatial) {
    layers <- c(layers, list(
      ggspatial::annotation_north_arrow(
        location = "tl", which_north = "true",
        style = ggspatial::north_arrow_orienteering,
        height = unit(1.0, "cm"), width = unit(0.8, "cm"),
        pad_x = unit(0.35, "cm"), pad_y = unit(0.35, "cm")),
      ggspatial::annotation_scale(
        location = "br", style = "ticks", width_hint = 0.16,
        height = unit(0.12, "cm"), line_width = 0.5, text_cex = 0.8)
    ))
  }
  c(layers, list(map_base_theme))
}
