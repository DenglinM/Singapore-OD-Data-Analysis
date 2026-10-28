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