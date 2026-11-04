# Data

Files in `data/raw/` and `data/processed/` are **not committed to GitHub** (see `.gitignore`). Each team member downloads or generates them locally. This file only records where each dataset comes from, where it lives and what it is called, so everyone has the same local paths and the scripts run unchanged.

## Folder conventions

| Folder | Contents | Editable? |
|---|---|---|
| `data/raw/` | Raw data downloaded from the official source, original file names kept | Read-only, never edit by hand |
| `data/processed/` | Cleaned data produced by the scripts in `scripts/` | Written by scripts only; safe to delete and regenerate |

## Data sources

| Dataset | Source | Local path | Notes |
|---|---|---|---|
| Origin-Destination Train (monthly station-to-station OD volume) | LTA DataMall, Dynamic Datasets → Passenger Volume by Origin Destination Train Stations | `data/raw/OD/origin_destination_train_YYYYMM.csv` | Requires a DataMall AccountKey; only the last 3 months are available |
| Origin-Destination Bus (monthly stop-to-stop OD volume) | LTA DataMall, Dynamic Datasets → Passenger Volume by Origin Destination Bus Stops | `data/raw/OD/origin_destination_bus_YYYYMM.csv` | Bus stop codes have leading zeros; read them as text (see `R/od_io.R`) |
| Passenger Volume by Train Stations (tap-in / tap-out) | LTA DataMall | `data/raw/station_volume/transport_node_train_YYYYMM.csv` | As above |
| MRT station locations / exits | LTA DataMall (Static Datasets → Train Station Exit Point, etc.) | `data/raw/spatial/` | CRS is SVY21 (EPSG:3414) |
| Land use (Master Plan Land Use) | data.gov.sg / URA Master Plan | `data/raw/spatial/` | |

> When you add a new dataset, add a row to this table and mention it in your PR description.

## Processed data

`scripts/Project R Markdown.Rmd` converts the OD CSVs once into a Parquet dataset at `data/processed/od_parquet/MODE=<train|bus>/YYYYMM=<YYYYMM>/` via `build_od_parquet()` in `R/od_io.R`. It can be deleted and regenerated at any time.

## Secrets

Put your DataMall AccountKey in `.Renviron` at the repo root (ignored by `.gitignore`; **never commit it**):

```
LTA_ACCOUNT_KEY=your_key
```

Read it in R with `Sys.getenv("LTA_ACCOUNT_KEY")`.

## Sharing large files

Raw CSVs and spatial data (Shapefile, GeoPackage, etc.) are large. Share them through the group's cloud drive (OneDrive / Google Drive, etc.) and put the link here. Do not put them in Git.

Onedrive link: [text](https://nusu-my.sharepoint.com/:f:/g/personal/e1583077_u_nus_edu/IgAazAbWTvmdSbwt_ErRwruHAR8DgD0wtEHqtthyC1Jkmjs?e=jRJYmq)


## STEP 1 spatial joining

Official code/name reference: [LTA Train Station Codes and Chinese Names (ZIP)](https://datamall.lta.gov.sg/content/dam/datamall/datasets/Geospatial/Train%20Station%20Codes%20and%20Chinese%20Names.zip). Extract the `.xls` into `data/raw/reference/` or set `AR5302_STATION_REFERENCE`. `scripts/03_station_code_crosswalk.R` uses `readxl` to build the crosswalk from this reference and all observed OD codes; small officially sourced additions are documented in `config/station_reference_supplements.R`. Generated crosswalk, OD code inventory, alignment audit and incremental scan cache live under `data/processed/spatial_join_inputs/`. No Excel or OD data is committed.

See [the STEP 1 run guide](../docs/step1_spatial_join.md) and edit `config/spatial_join.R` before running `scripts/04_spatial_join.R`.

| Dataset | Source | Local path / convention | Notes |
|---|---|---|---|
| Master Plan 2019 Subzone Boundary | URA via data.gov.sg / group shared drive | `data/raw/spatial/MP2019_Subzone.gpkg` (configurable) | Must be the 2019 polygon boundary; configure code/name fields and layer |
| Bus stop points | LTA DataMall / group shared drive | `data/raw/spatial/BusStop.shp` or CSV (configurable) | Five-character stop codes; CSV coordinates require explicit CRS |
| Station name-to-OD-code crosswalk | Team-verified against LTA station metadata and observed OD codes | `data/raw/spatial/station_code_crosswalk.csv` | Columns `station_key,station_code`; explicit aliases, no inferred codes |
| Reviewed subzone overrides (optional) | Team GIS review with recorded evidence | Configured local CSV | Columns `mode,node_code,subzone_code,reason` |

The exit-point path defaults to `data/raw/spatial/TrainStationExitPoint.shp`; configure the actual filename and station-key field. Spatial files use their own CRS metadata, then transform to EPSG:3414. Do not assume every source is already SVY21. Use node snapshots suitable for the OD study period, including historical stops where needed.

The script writes unique MRT/bus lookup CSVs, point-level matches, duplicates, unresolved matches and OD-code coverage reports under `data/processed/spatial_join/`. Raw inputs, crosswalks, overrides and generated tables remain local and are not committed. No real raw spatial or OD files were available during implementation; the test suite uses synthetic geometries.

