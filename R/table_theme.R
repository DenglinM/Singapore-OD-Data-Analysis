# Shared three-line table (三线表) style for the group project
# ---------------------------------------------------------------
# source(here::here("R", "table_theme.R")) in any Rmd. Then:
#   stylized_table(data)                                  # whole table
#   stylized_table(data, cols = c(Centre = centre, trips)) # pick / rename columns
#   stylized_table(data, group = sample)                  # merged group column
#   save_table(tab, "output/tables/table1.docx")          # export
# Change line widths, font or number format HERE and every table follows.
#
# Works when knitting to HTML, Word and PDF (uses flextable).
# install.packages(c("flextable", "officer"), type = "binary")

library(flextable)
library(officer)

# ---- Style settings: edit these once, all tables follow ----------------
table_style <- list(
  font       = "Times New Roman",
  font_size  = 10.5,
  note_size  = 9,
  thick_line = fp_border(color = "black", width = 1.5),  # top + bottom rule
  thin_line  = fp_border(color = "black", width = 0.75), # rule under header
  big_mark   = ",",
  na_str     = "–"
)

# ---- stylized_table(data, ...) ------------------------------------------
# data   : a data frame / tibble
# cols   : columns to show, unquoted, tidyselect style. Rename on the fly:
#          cols = c(Centre = centre, `Trips (k)` = trips)
# labels : optional header labels, named vector c(column = "Label")
# group  : optional grouping column (unquoted); moved to the front and
#          repeated values are merged into one cell
# digits : decimals for non-integer numbers. One number for all columns,
#          or named: digits = c(share = 1, dist_km = 2)
# title  : caption above the table ("Table 1. ...")
# note   : text under the bottom rule ("Note: ..." / "Source: ...")
# bold_header : TRUE to bold the header row
# width  : optional total width in inches; default fits content
stylized_table <- function(data, cols = NULL, labels = NULL, group = NULL,
                           digits = 2, title = NULL, note = NULL,
                           bold_header = FALSE, width = NULL) {
  df <- as.data.frame(data)

  # pick / rename columns
  if (!rlang::quo_is_null(rlang::enquo(cols))) {
    df <- dplyr::select(df, {{ cols }})
  }

  # group column goes first and gets merged
  qg <- rlang::enquo(group)
  group_name <- NULL
  if (!rlang::quo_is_null(qg)) {
    group_name <- rlang::as_name(qg)
    df <- dplyr::relocate(df, dplyr::all_of(group_name))
    df[[group_name]] <- as.character(df[[group_name]])
  }

  ft <- flextable(df)

  # header labels
  if (!is.null(labels)) {
    labels <- labels[names(labels) %in% names(df)]
    ft <- set_header_labels(ft, values = as.list(labels))
  }

  # number format: integers with thousands mark, doubles with digits
  ft <- colformat_int(ft, big.mark = table_style$big_mark, na_str = table_style$na_str)
  dbl_cols <- names(df)[vapply(df, is.double, logical(1))]
  for (col in dbl_cols) {
    named <- !is.null(names(digits)) && col %in% names(digits)
    whole <- all(df[[col]] %% 1 == 0, na.rm = TRUE)  # e.g. counts stored as double
    d <- if (named) digits[[col]]
         else if (whole) 0
         else if (is.null(names(digits))) digits[[1]] else 2
    ft <- colformat_double(ft, j = col, digits = d,
                           big.mark = table_style$big_mark,
                           na_str = table_style$na_str)
  }

  # merge repeated group values
  if (!is.null(group_name)) {
    ft <- merge_v(ft, j = group_name)
    ft <- valign(ft, j = group_name, valign = "top", part = "body")
  }

  # the three lines
  ft <- border_remove(ft)
  ft <- hline_top(ft, part = "header", border = table_style$thick_line)
  ft <- hline_bottom(ft, part = "header", border = table_style$thin_line)
  ft <- hline_bottom(ft, part = "body", border = table_style$thick_line)

  # alignment: first column left, the rest centred
  ft <- align(ft, j = 1, align = "left", part = "all")
  if (ncol(df) > 1) ft <- align(ft, j = 2:ncol(df), align = "center", part = "all")

  # font
  ft <- font(ft, fontname = table_style$font, part = "all")
  ft <- fontsize(ft, size = table_style$font_size, part = "all")
  if (bold_header) ft <- bold(ft, part = "header")
  ft <- padding(ft, padding.top = 2, padding.bottom = 2, part = "all")

  # note under the bottom rule (no line under it)
  if (!is.null(note)) {
    ft <- add_footer_lines(ft, values = note)
    ft <- fontsize(ft, size = table_style$note_size, part = "footer")
    ft <- font(ft, fontname = table_style$font, part = "footer")
    ft <- align(ft, align = "left", part = "footer")
  }

  # title in the same font as the table (falls back to plain text on old flextable)
  if (!is.null(title)) {
    ft <- tryCatch(
      set_caption(ft, caption = as_paragraph(as_chunk(title,
        props = fp_text_default(font.family = table_style$font,
                                font.size = table_style$font_size + 1)))),
      error = function(e) set_caption(ft, caption = title))
  }

  ft <- autofit(ft)
  if (!is.null(width)) ft <- fit_to_width(ft, max_width = width)
  ft
}

# ---- save_table(table, path) --------------------------------------------
# .docx -> Word table you can paste into the report (no extra package)
# .png  -> image; needs install.packages("webshot2")
# .html -> standalone web page
save_table <- function(table, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ext <- tolower(tools::file_ext(path))
  switch(ext,
    docx = save_as_docx(table, path = path),
    png  = save_as_image(table, path = path),
    html = save_as_html(table, path = path),
    stop("Use a .docx, .png or .html file name.")
  )
  invisible(path)
}
