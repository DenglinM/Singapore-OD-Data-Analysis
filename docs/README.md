# docs/

Documentation: research design, meeting notes, literature notes, report drafts, etc.

Suggested layout:

- `meeting_notes/`: meeting notes, named `YYYY-MM-DD.md`
- `literature/`: literature notes
- `report/`: final report. `report/report.Rmd` only embeds the PNG figures saved by the analysis Rmds in `outputs/figures/`, so it knits without the raw data (see `R/save_fig.R`)
