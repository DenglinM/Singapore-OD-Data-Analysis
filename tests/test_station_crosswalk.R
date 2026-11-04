source("R/spatial_join.R")
source("R/station_crosswalk.R")
ref <- data.frame(stn_code = c("NS1", "EW24", "NS2"),
  mrt_station_english = c("Jurong East", "Jurong East", "Bukit Batok"))
r <- build_station_crosswalk(ref, c("JURONG EAST MRT STATION", "BUKIT BATOK MRT STATION"),
  c("NS1/EW24", "EW24/NS1", "NS1/NS2", "ZZ99"))
stopifnot(nrow(r$crosswalk) == 4L, !anyDuplicated(r$crosswalk$station_code),
  r$audit$station_key[r$audit$station_code == "EW24/NS1"] == "JURONG EAST MRT STATION",
  r$audit$alignment_status[r$audit$station_code == "NS1/NS2"] == "composite_spans_station_names",
  r$audit$alignment_status[r$audit$station_code == "ZZ99"] == "code_missing_from_reference")
missing <- build_station_crosswalk(ref, "JURONG EAST MRT STATION", "NS2")
stopifnot(missing$audit$alignment_status[missing$audit$station_code == "NS2"] == "station_name_missing_from_exits")
expect_error <- function(expr) stopifnot(inherits(tryCatch({force(expr); NULL}, error=identity), "error"))
separate <- build_station_crosswalk(ref, c("JURONG EAST MRT STATION", "JURONG EAST LRT STATION"), "NS1")
stopifnot(separate$crosswalk$station_key[separate$crosswalk$station_code == "NS1"] == "JURONG EAST MRT STATION")
lrt_ref <- data.frame(stn_code=c("NE17","PTC"),mrt_station_english=c("Punggol","Punggol"))
lrt <- build_station_crosswalk(lrt_ref,c("PUNGGOL MRT STATION","PUNGGOL LRT STATION"),c("NE17","PTC","NE17/PTC"))
stopifnot(lrt$audit$alignment_status[lrt$audit$station_code == "NE17/PTC"] == "matched",
  lrt$crosswalk$station_key[lrt$crosswalk$station_code == "PTC"] == "PUNGGOL LRT STATION")
st <- data.frame(node_id=c("PUNGGOL MRT STATION","PUNGGOL LRT STATION"),
  subzone_code=c("A","A"), match_status="matched", n_points=1L,
  n_candidate_subzones=1L, candidate_subzones=c("A","A"))
combined <- append_station_groups(st,lrt$crosswalk)
stopifnot(nrow(combined)==3L,combined$match_status[3]=="matched",combined$n_points[3]==2L)
aligned <- align_stations(combined,lrt$crosswalk)
stopifnot("source_station_keys" %in% names(aligned), !is.na(aligned$source_station_keys[3]))
st$subzone_code[2]<-"B"; st$candidate_subzones[2]<-"B"
combined <- append_station_groups(st,lrt$crosswalk)
stopifnot(combined$match_status[3]=="multiple_exit_groups_unresolved",is.na(combined$subzone_code[3]))
tmp <- tempfile("code_cache_"); dir.create(tmp)
f <- file.path(tmp, "origin_destination_train_202001.csv")
readr::write_csv(data.frame(ORIGIN_PT_CODE="NS1", DESTINATION_PT_CODE="NS2"),f)
cache <- file.path(tmp,"cache.rds")
first <- build_od_inventory(f,cache)
second <- build_od_inventory(f,cache)
stopifnot(identical(first,second),nrow(first)==2L)
readr::write_csv(data.frame(ORIGIN_PT_CODE="NS1/EW24", DESTINATION_PT_CODE="NS2"),f)
third <- build_od_inventory(f,cache)
stopifnot("NS1/EW24" %in% third$pt_code)
cat("Station crosswalk and cache tests passed.\n")
stopifnot(normalise_node_code("CC1-NE6-NS24", "train") == "CC1/NE6/NS24",
  normalise_node_code("EW24-NS1", "train") == "EW24/NS1")
