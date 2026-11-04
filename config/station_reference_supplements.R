# Explicit additions missing from LTA's January 2025 Excel reference.
# Code/name facts only; this does not assert operation in every OD month.
station_reference_supplements <- data.frame(
  stn_code = c("CC30", "CC31", "CC32", "TE21", "CC33", "CC34"),
  mrt_station_english = c("Keppel", "Cantonment", "Prince Edward Road", "Marina South", "Marina Bay", "Bayfront"),
  source_url = c(rep("https://www.lta.gov.sg/content/ltagov/en/newsroom/2026/5/news-releases/circle-line-stage-6-to-open-for-public-preview-on-4-july-2026.html", 3),
    "https://www.seab.gov.sg/files/Train%20Disruption/JC__Thomson_East_Coast_Line.pdf",
    rep("https://www.lta.gov.sg/content/ltagov/en/getting_around/public_transport/a_better_public_transport_experience/art_in_public_transport/art_in_transit.html", 2)),
  stringsAsFactors = FALSE
)
