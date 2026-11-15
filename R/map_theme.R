# Shared plot style for the group project
# =============================================================================
# source(here::here("R", "map_theme.R")) in any Rmd, then:
#   1. MAPS         sg_map(data, var, ...)
#   2. LINE CHARTS  stylized_line(x, y, z)
#   3. MATRICES     stylized_matrix(x, y, z)
# Change colours, fonts or layout HERE and every figure of the group follows.
# =============================================================================

library(ggplot2)
library(sf)
`%||%` <- function(a, b) if (is.null(a)) b else a

# Fixed order of the four centres (matrix rows/columns, line colours ...)
centre_order <- c("Woodlands", "Tampines", "Jurong Lake District", "CBD")


# =============================================================================
# 1. MAPS
# =============================================================================

# ---- Colours and labels ------------------------------------------------------
# Service-shed classes, same colours as Hou et al. (2025):
# red = core, orange = strong, yellow = weak, pale green = peripheral.
# "No flow" is drawn white but not listed in the legend.
shed_levels  <- c("Core", "Strong", "Weak", "Peripheral", "No flow")
shed_colours <- c("Core" = "#d7191c", "Strong" = "#fd8d3c", "Weak" = "#ffe34d",
                  "Peripheral" = "#cfe8c0", "No flow" = "white")
shed_breaks  <- c("Core", "Strong", "Weak", "Peripheral")
shed_labels  <- c("Core (0-25 %)", "Strong (25-50 %)", "Weak (50-75 %)",
                  "Peripheral (75-100 %)")
mode_label   <- c(train = "MRT/LRT", bus = "Bus")

# MRT lines (official LTA colours). Thomson-East Coast Line is left out on
# purpose: it opened in stages (2020-2024), so most of it did not exist in the
# 2021-2022 study periods. Add "Thomson-East Coast Line" = "#9D5B25" for 2024+.
mrt_line_names <- c(NS = "North South Line", EW = "East West Line",
                    NE = "North East Line",  CC = "Circle Line",
                    DT = "Downtown Line",    TE = "Thomson-East Coast Line")
mrt_line_colours <- c("North South Line" = "#D42E12", "East West Line" = "#009645",
                      "Downtown Line"    = "#005EC4", "North East Line" = "#9900AA",
                      "Circle Line"      = "#FA9E0D")

# ggspatial (scale bar, north arrow) is optional: maps still work without it
has_ggspatial <- requireNamespace("ggspatial", quietly = TRUE)

# ---- Map theme and frame -----------------------------------------------------
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

# ---- One framed legend box in the lower-right corner (single maps) ----------
legend_inside <- function(x = 0.99, y = 0.02) {
  theme(legend.position        = "inside",
        legend.position.inside = c(x, y),
        legend.justification   = c(1, 0),
        legend.box             = "vertical",
        legend.box.just        = "left",
        legend.background      = element_blank(),
        legend.box.background  = element_rect(fill = "white", colour = "black",
                                              linewidth = 0.4),
        legend.box.margin      = margin(4, 6, 4, 6),
        legend.margin          = margin(0, 0, 0, 0),
        legend.spacing.y       = unit(2, "pt"),
        legend.key.size        = unit(0.38, "cm"),
        legend.title           = element_text(size = 9, face = "bold"),
        legend.text            = element_text(size = 7.5))
}

# ---- sg_map(): any Singapore subzone map in one call -------------------------
# Contains every element a map needs (fill layer, optional MRT lines and
# outlines, frame, lon/lat axes, north arrow, scale bar, titles). Returns a
# ggplot, so more layers can still be added with `+`.
#
#   data         sf polygons (any CRS; drawn in EPSG:3414)
#   var          column to colour by (unquoted), e.g. pop or shed
#   type         "auto": numbers -> binned colours, text/factor -> categories
#                "binned" / "continuous" / "discrete" to force one
#   values       named colours for discrete maps, e.g. shed_colours
#   breaks       which classes appear in the legend, e.g. shed_breaks
#   option       viridis palette for numeric maps ("A"-"H"; "C" = plasma)
#   trans        e.g. "log10" for skewed counts (continuous / binned)
#   mrt_lines    output of make_mrt_lines() to draw coloured lines on top
#   outline      sf polygons drawn as black outlines (e.g. a centre boundary);
#                when given, distance rings, a ruler and the centre point are
#                drawn around it
#   rings_km     ring distances in km (NULL = no rings)
#   centre_label text next to the centre point (default: outline$centre)
#   legend       "inside" (one framed box, lower right) or "right";
#                multi-panel maps always put the legend on the right
#   facet        column (unquoted) that splits the map into panels, e.g. panel.
#                Panels are filled column by column and lettered (a), (b), ...
#                like Hou et al. Fig 4.1. `data` must hold one copy of the
#                polygons per panel (see the example below).
#   ncol         number of panel columns
#
# Examples:
#   sg_map(sz_pop, pop, legend_title = "Residents", title = "Population 2020")
#   # multi-panel: one copy of the subzones per period, then facet = panel
#   sg_map(panel_data, shed, values = shed_colours, labels = shed_labels,
#          facet = panel, ncol = 2, outline = cbd_outline)
#   sg_map(map_data, shed, values = shed_colours, breaks = shed_breaks,
#          labels = shed_labels,
#          mrt_lines = geo$mrt_lines, outline = geo$outline)
sg_map <- function(data, var, legend_title = NULL,
                   title = NULL, subtitle = NULL, caption = NULL,
                   type = c("auto", "binned", "continuous", "discrete"),
                   values = NULL, labels = waiver(), breaks = waiver(), option = "C",
                   trans = "identity", n_breaks = 6,
                   mrt_lines = NULL, outline = NULL,
                   rings_km = c(5, 10, 15), centre_label = NULL,
                   legend = c("inside", "right"),
                   facet = NULL, ncol = 2,
                   bb = NULL) {
  legend <- match.arg(legend)
  faceted <- !rlang::quo_is_null(rlang::enquo(facet))
  type <- match.arg(type)
  data <- sf::st_transform(data, 3414)
  if (is.null(bb)) bb <- sf::st_bbox(data)

  vals <- sf::st_drop_geometry(data) |> dplyr::pull({{ var }})
  if (type == "auto") type <- if (is.numeric(vals)) "binned" else "discrete"

  fill_scale <- switch(type,
    binned = scale_fill_viridis_b(
      option = option, n.breaks = n_breaks, trans = trans, name = legend_title,
      limits = stats::quantile(vals, c(0.01, 0.99), na.rm = TRUE),
      oob = scales::squish, na.value = "grey95"),
    continuous = scale_fill_viridis_c(
      option = option, trans = trans, name = legend_title, na.value = "grey95"),
    discrete = if (!is.null(values)) {
      # Legend lists only named classes, never NA; NA areas are drawn white
      # (default: the first classes of `values`, as many as there are labels,
      #  so shed_colours + shed_labels shows Core ... Peripheral only)
      if (inherits(breaks, "waiver")) {
        breaks <- if (inherits(labels, "waiver")) names(values)
                  else names(values)[seq_along(labels)]
      }
      scale_fill_manual(values = values, labels = labels, breaks = breaks,
                        name = legend_title %||% "Legend",
                        drop = FALSE, na.value = "white")
    } else {
      scale_fill_viridis_d(option = option, name = legend_title, na.value = "grey95")
    }
  )

  p <- ggplot() +
    geom_sf(data = data, aes(fill = {{ var }}), colour = "grey60", linewidth = 0.08) +
    fill_scale

  if (!is.null(mrt_lines)) {
    p <- p +
      geom_sf(data = dplyr::filter(mrt_lines, line %in% names(mrt_line_colours)),
              aes(colour = line), linewidth = 0.3,
              key_glyph = draw_key_path) +
      scale_colour_manual(values = mrt_line_colours, breaks = names(mrt_line_colours),
                          name = NULL)
  }

  if (!is.null(outline)) {
    outline <- sf::st_transform(outline, 3414)
    p <- p + geom_sf(data = outline, fill = NA, colour = "black", linewidth = 0.6)

    # Centre point, distance rings and a ruler to the east, like the paper
    pt <- sf::st_centroid(sf::st_union(outline))
    xy <- sf::st_coordinates(pt)
    if (is.null(centre_label) && "centre" %in% names(outline)) {
      centre_label <- paste(unique(outline$centre), collapse = " / ")
    }
    if (length(rings_km) > 0) {
      rings <- sf::st_sf(geometry = sf::st_boundary(
        sf::st_buffer(pt[rep(1, length(rings_km))], rings_km * 1000)))
      ruler <- tibble::tibble(x = xy[1], y = xy[2],
                              xend = xy[1] + max(rings_km) * 1000, yend = xy[2])
      ring_lab <- tibble::tibble(x = xy[1] + rings_km * 1000, y = xy[2],
                                 label = paste0(rings_km, "km"))
      p <- p +
        geom_sf(data = rings, colour = "#8b1a1a", linetype = "dashed", linewidth = 0.35) +
        geom_segment(data = ruler, aes(x = x, y = y, xend = xend, yend = yend),
                     colour = "#8b1a1a", linewidth = 0.35) +
        geom_label(data = ring_lab, aes(x = x, y = y, label = label),
                   size = 2.6, vjust = -0.3, fill = "white", label.size = 0,
                   label.padding = unit(0.06, "lines"))
    }
    p <- p +
      geom_point(data = tibble::tibble(x = xy[1], y = xy[2]), aes(x = x, y = y),
                 size = 2.6, colour = "black")
    if (!is.null(centre_label)) {
      p <- p + geom_label(data = tibble::tibble(x = xy[1], y = xy[2], label = centre_label),
                          aes(x = x, y = y, label = label), size = 2.8, vjust = 1.4,
                          fill = "white", label.size = 0,
                          label.padding = unit(0.06, "lines"))
    }
  }

  p <- p + map_layers(bb) +
    labs(x = NULL, y = NULL, title = title, subtitle = subtitle, caption = caption) +
    guides(fill = guide_legend(order = 1, override.aes = list(colour = "grey45")),
           colour = guide_legend(order = 2))
  if (faceted) {
    # Panel titles "(a) <value>", "(b) <value>" ... filled column by column
    panel_vals <- unique(as.character(sf::st_drop_geometry(data) |> dplyr::pull({{ facet }})))
    tags <- stats::setNames(paste0("(", letters[seq_along(panel_vals)], ") ", panel_vals),
                            panel_vals)
    p <- p +
      facet_wrap(vars(factor({{ facet }}, levels = panel_vals)), ncol = ncol, dir = "v",
                 labeller = as_labeller(tags)) +
      theme(axis.text = element_text(size = 7))
  } else if (legend == "inside") {
    p <- p + legend_inside()
  }
  p
}

# =============================================================================
# 2. LINE CHARTS
# =============================================================================
# Each group has its own colour, line type and hollow marker (circle, square,
# triangle, diamond), so the chart also reads in black and white.
# Axes: left + bottom lines only, outward ticks, no grid.
line_colours <- c("#3e7c99", "#c8874a", "#7e9c78", "#9a6b8f")  # blue, ochre, sage, plum
line_types   <- c("solid", "dashed", "dotted", "dotdash")
line_shapes  <- c(21, 22, 24, 23)                              # circle, square, triangle, diamond

line_chart_theme <- theme_classic(base_size = 11) +
  theme(
    axis.line          = element_line(colour = "grey30", linewidth = 0.5),
    axis.ticks         = element_line(colour = "grey30", linewidth = 0.5),
    axis.ticks.length  = unit(4, "pt"),
    axis.text          = element_text(colour = "grey15"),
    legend.position    = "top",
    legend.direction   = "horizontal",
    legend.key.width   = unit(1.3, "cm"),
    legend.title       = element_text(size = 10),
    legend.text        = element_text(size = 10),
    plot.title.position   = "plot",
    plot.caption.position = "plot",
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 9, colour = "grey25"),
    plot.caption  = element_text(size = 7.5, colour = "grey35", hjust = 0),
    plot.margin   = margin(8, 12, 8, 8)
  )

# stylized_line(x, y, z): x = horizontal axis, y = values, z = groups.
# Vectors:       stylized_line(df$month, df$trips, df$centre)
# Column names:  stylized_line(month, trips, centre, data = df)
# The four centres are drawn in centre_order.
stylized_line <- function(x, y, z = NULL, data = NULL,
                          x_lab = NULL, y_lab = NULL, legend_title = NULL,
                          title = NULL, subtitle = NULL, caption = NULL,
                          y_labels = scales::label_comma()) {
  qx <- rlang::enquo(x); qy <- rlang::enquo(y); qz <- rlang::enquo(z)
  d <- tibble::tibble(
    x = rlang::eval_tidy(qx, data),
    y = rlang::eval_tidy(qy, data),
    z = if (rlang::quo_is_null(qz)) "all" else as.character(rlang::eval_tidy(qz, data))
  )
  lv <- if (all(unique(d$z) %in% centre_order)) centre_order[centre_order %in% d$z]
        else unique(d$z)
  d$z <- factor(d$z, levels = lv)
  one_group <- rlang::quo_is_null(qz)
  k <- length(lv)

  # Numeric x with few values (e.g. 0, 2 ... 12): a tick at every value
  x_scale <- if (is.numeric(d$x) && dplyr::n_distinct(d$x) <= 15) {
    scale_x_continuous(breaks = sort(unique(d$x)), expand = expansion(mult = 0.03))
  } else NULL
  legend_guide <- if (one_group) "none" else guide_legend(title.position = "top",
                                                          title.hjust = 0.5)

  ggplot(d, aes(x = x, y = y, group = z)) +
    geom_line(aes(colour = z, linetype = z), linewidth = 0.9) +
    geom_point(aes(colour = z, shape = z), fill = "white", size = 2.6, stroke = 1) +
    scale_colour_manual(values = rep(line_colours, length.out = k), name = legend_title) +
    scale_linetype_manual(values = rep(line_types, length.out = k), name = legend_title) +
    scale_shape_manual(values = rep(line_shapes, length.out = k), name = legend_title) +
    x_scale +
    scale_y_continuous(labels = y_labels, expand = expansion(mult = c(0.05, 0.08))) +
    guides(colour = legend_guide, linetype = legend_guide, shape = legend_guide) +
    labs(x = x_lab %||% rlang::as_label(qx), y = y_lab %||% rlang::as_label(qy),
         title = title, subtitle = subtitle, caption = caption) +
    line_chart_theme

}


# =============================================================================
# 3. MATRICES
# =============================================================================
# Square tiles, yellow-green-blue colours (light = low, dark blue = high),
# row labels on the right, column labels at the bottom (vertical), and a
# horizontal colour bar under the matrix.
#   x = column, y = row, z = value in the cell
#   order        order of the categories (same for rows and columns);
#                default: centre_order (Woodlands, Tampines, Jurong Lake
#                District, CBD); other categories keep their order of appearance
#   show_values  write the value in each cell
#   tag          panel letter, e.g. "A"
# Example (overlap of principal sheds, read by column):
#   stylized_matrix(j, i, O, data = overlap_matrix(sheds), limits = c(0, 1),
#                   title = "Overlap of principal service sheds")
stylized_matrix <- function(x, y, z, data = NULL, order = centre_order,
                            legend_title = NULL, title = NULL, subtitle = NULL,
                            caption = NULL, tag = NULL, limits = NULL,
                            labels = scales::label_percent(accuracy = 1),
                            show_values = TRUE,
                            value_labels = labels) {
  qx <- rlang::enquo(x); qy <- rlang::enquo(y); qz <- rlang::enquo(z)
  d <- tibble::tibble(x = as.character(rlang::eval_tidy(qx, data)),
                      y = as.character(rlang::eval_tidy(qy, data)),
                      value = rlang::eval_tidy(qz, data))
  # Use the fixed order when it covers every category, otherwise the order
  # in which the categories first appear in x
  lv <- if (!is.null(order) && all(unique(d$x) %in% order)) {
    order[order %in% d$x]
  } else unique(d$x)
  # Columns left -> right and rows top -> bottom in the same order,
  # so the diagonal runs from top-left to bottom-right
  d <- d |> dplyr::mutate(x = factor(x, levels = lv),
                          y = factor(y, levels = rev(lv)))
  if (is.null(limits)) limits <- range(d$value, na.rm = TRUE)

  p <- ggplot(d, aes(x = x, y = y, fill = value)) +
    geom_tile() +
    scale_fill_distiller(
      palette = "YlGnBu", direction = 1, limits = limits, labels = labels,
      name = legend_title, na.value = "grey90",
      guide = guide_colourbar(direction = "horizontal", title.position = "top",
                              title.hjust = 0.5,
                              barwidth = unit(3, "cm"), barheight = unit(0.3, "cm"),
                              frame.colour = "grey20", ticks.colour = "grey20")) +
    scale_x_discrete(expand = c(0, 0), labels = scales::label_wrap(10)) +
    scale_y_discrete(expand = c(0, 0), position = "right",
                     labels = scales::label_wrap(10)) +
    coord_fixed() +
    labs(x = NULL, y = NULL, title = title, subtitle = subtitle,
         caption = caption, tag = tag) +
    theme_void(base_size = 10) +
    theme(axis.text.y.right = element_text(colour = "grey15", size = 9, hjust = 0,
                                           margin = margin(l = 5)),
          axis.text.x     = element_text(colour = "grey15", size = 9, angle = 90,
                                         vjust = 0.5, hjust = 1, margin = margin(t = 5)),
          legend.position = "bottom",
          legend.justification = "right",
          legend.margin   = margin(t = 6),
          legend.title    = element_text(size = 8),
          legend.text     = element_text(size = 7, colour = "grey20"),
          plot.title.position = "panel",
          plot.title      = element_text(size = 11, hjust = 0.5, margin = margin(b = 6)),
          plot.subtitle   = element_text(size = 8.5, colour = "grey25", hjust = 0.5),
          plot.caption    = element_text(size = 7, colour = "grey35", hjust = 0),
          plot.tag        = element_text(face = "bold", size = 13),
          plot.tag.position = "topleft",
          plot.margin     = margin(10, 10, 10, 10))

  if (show_values) {
    mid <- mean(limits)
    p <- p + geom_text(aes(label = value_labels(value), colour = value > mid),
                       size = 2.8, show.legend = FALSE) +
      scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "grey20"), guide = "none")
  }
  p
}
