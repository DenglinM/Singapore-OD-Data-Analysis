# outputs/figures/

Figures saved by the analysis Rmds with `save_fig()` (see `R/save_fig.R`) and
embedded by the summary report `docs/report/report.Rmd`.

**Commit the PNG files.** Then teammates who write the report can knit it
without downloading the OD data or re-running the analysis.

## Naming

`figNN_<mode>_<topic>.png`, lower case, no spaces. `NN` is the figure's planned
position in the report. To add a figure, pick the next free number, add a row
below, save it with `save_fig(p, "figNN_...")` and add a `show_fig()` chunk to
the report.

## Figure list

| File | Made by | Content |
|---|---|---|
| `fig01_centre_map.png` | `scripts/train_2021_2023.Rmd` | Map of the CBD and the three regional centres |
| `fig02_train_attraction_2021_2023.png` | `scripts/train_2021_2023.Rmd` | MRT AM-peak attraction share by centre |
| `fig03_train_cbd_outflow_2021_2023.png` | `scripts/train_2021_2023.Rmd` | Share of MRT trips from each regional centre that go to the CBD |
| `fig04_train_flow_matrix_2023.png` | `scripts/train_2021_2023.Rmd` | Centre-to-centre MRT flow matrix, March 2023 AM peak |
| `fig05_train_trip_distance_2021_2023.png` | `scripts/train_2021_2023.Rmd` | Mean MRT trip distance into each centre |
| `fig06_bus_attraction_2023_2026.png` | `scripts/Bus-2023-2026.Rmd` | Bus AM-peak attraction share by centre |
| `fig07_bus_cbd_outflow_2023_2026.png` | `scripts/Bus-2023-2026.Rmd` | Share of bus trips from each regional centre that go to the CBD |
| `fig08_bus_in_out_ratio_2023_2026.png` | `scripts/Bus-2023-2026.Rmd` | Bus inflow / outflow ratio by centre |
| `fig09_bus_trip_distance_2023_2026.png` | `scripts/Bus-2023-2026.Rmd` | Mean bus trip distance into each centre |
| `fig10_bus_weekend_arrivals_2023_2026.png` | `scripts/Bus-2023-2026.Rmd` | Weekend bus arrivals at the regional centres |
| `fig11_hub_land_use.png` | `scripts/Weekends.Rmd` | Land-use mix of the regional centres |
| `fig12_hub_poi_density.png` | `scripts/Weekends.Rmd` | POI density by category and centre |

Planned but not yet produced: MRT 2024-2026 indicators (`scripts/Train_2024_2026.Rmd`)
and bus 2021-2023 indicators (`scripts/bus_2021_2023.Rmd`). Maps made in QGIS
can be exported to this folder as PNG with the same naming rule and embedded
the same way.
