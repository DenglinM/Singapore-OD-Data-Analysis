# scripts/

Analysis scripts, numbered in run order. Running them top to bottom reproduces every result:

```
01_download_data.R     # download / organise raw data into data/raw/
02_clean_od.R          # clean OD data → data/processed/
03_reliability_check.R # data reliability checks
04_spatial_join.R      # join with station, land-use and other spatial data
05_analysis_*.R        # analysis for each research topic
```

Conventions:

STEP 1 station/stop-to-2019-subzone matching is implemented in `04_spatial_join.R`.
Configure `config/spatial_join.R`, then follow [the run guide](../docs/step1_spatial_join.md).
The other numbered filenames above describe the intended pipeline; they may not yet exist.

- Open `Singapore-OD-Data-Analysis.Rproj` in RStudio and write every path relative to the project root (preferably `here::here("data", "raw", ...)`). Never use absolute paths like `C:/Users/...`.
- Scripts read only from `data/` and write only to `data/processed/` and `outputs/`.
- Put reusable functions in `R/` and `source()` them at the top of the script.
- Start each script with a comment block stating the author, purpose, inputs and outputs.
