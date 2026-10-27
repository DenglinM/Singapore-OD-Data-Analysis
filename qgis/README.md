# qgis/

QGIS project and style files. QGIS is free and open source, so every team member can use it.

The main analysis is done in R / RStudio (spatial data handled with the `sf` package). QGIS is mainly used to view and check spatial data, verify station locations by hand, and make maps for the report.

## Commit

- Project files. **Save projects as `.qgs`** (choose `.qgs` in Project → Save As): it is plain-text XML, so Git can show what changed. The default `.qgz` is a zip archive that Git cannot diff or merge.
- Layer styles `.qml`, print layout templates `.qpt`, processing models `.model3`.

## Do not commit

- The data itself (Shapefile, GeoPackage, GeoJSON, etc.). Put it in `data/raw/` or `data/processed/` and reference it from the project.
- Backup files `*.qgs~` / `*.qgz~` and GeoPackage temporary files (already ignored in `.gitignore`).

## Notes

- Use relative paths: Project → Properties → General → Save paths → **Relative** (the QGIS default). This way layers still load when someone else clones the repo and opens the project.
- Use **SVY21 / Singapore TM (EPSG:3414)** as the CRS throughout.
- Even with `.qgs`, several people editing the same project at once causes conflicts. Tell the group before editing, or give each person their own project file (e.g. `od_map_<name>.qgs`).
- Put exported maps in `outputs/figures/`.
