# Singapore MRT OD Data Analysis

An analysis of origin-destination (OD) ridership data from Singapore's public transport system (MRT), combined with spatial data such as station locations and land use. The aims are to:

1. verify the reliability of the OD data;
2. identify valuable research topics (e.g. the relationship between station land use and ridership).

Tools: **R / RStudio** is the main analysis platform (spatial data handled with `sf`). **QGIS**, which is free and open source so every team member can use it, is used for mapping and checking spatial data.

## Repository structure

```
.
├── data/
│   ├── raw/            # raw data (not committed, see data/README.md)
│   ├── processed/      # intermediate data produced by scripts (not committed)
│   └── README.md       # data sources, download instructions, file naming
├── scripts/            # analysis scripts, run in order: 01_*.R, 02_*.R ...
├── R/                  # reusable R functions
├── qgis/               # QGIS projects (.qgs), layer styles, layout templates
├── outputs/
│   ├── figures/        # figures and finished maps
│   └── tables/         # result tables (small files)
├── docs/               # research design, meeting notes, report drafts
├── CONTRIBUTING.md     # team workflow (read this first)
└── Singapore-OD-Data-Analysis.Rproj
```

## Getting started

1. Clone the repository:
   ```bash
   git clone https://github.com/DenglinM/Singapore-OD-Data-Analysis.git
   ```
2. Open `Singapore-OD-Data-Analysis.Rproj` in RStudio (this makes the project root your working directory).
3. Download the data as described in [`data/README.md`](data/README.md) and place it under `data/raw/`.
4. Run the scripts in `scripts/` in numbered order.

## About data files

**Do not commit raw data or large files to GitHub.** The OD data is hundreds of MB per month, GitHub rejects files over 100 MB, and once a large file enters the repo it stays in the history even after deletion, slowing every clone. `.gitignore` already excludes `data/raw/`, `data/processed/`, archives and QGIS backup files. Share large files through the group's cloud drive and put the link in `data/README.md`.

## Collaboration

Please read [CONTRIBUTING.md](CONTRIBUTING.md) first. In short, `main` is protected, and every change goes through **branch → commit → pull request → review by a teammate → merge**.

## License

[MIT](LICENSE)
