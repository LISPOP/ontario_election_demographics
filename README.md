# Ontario Election Results + Riding Demographics

A self-contained pipeline that builds a single dataset joining **Ontario provincial
election results (2018, 2022, 2025)** to **2021 Census demographics** for each electoral
district. Northern ridings' demographics are estimated from Statistics Canada dissemination
areas via `tongfen`; the remaining ("non-northern") ridings pull federal-electoral-district
figures directly from the Statistics Canada WDS.

## Output

Running the pipeline writes two files to `data/`:

| File | Contents |
|------|----------|
| `ontario_demographics.csv` | Province-wide demographics table, one row per electoral district (keyed on `ED_ID`). |
| `ontario_election_demographics.csv` | **The deliverable** — 2018/2022/2025 election results (one row per candidate) with each riding's demographics joined on. |

## How to run

Open `ontario_election_demographics.Rproj` in RStudio (or set the working directory to the
project root), then source the top of the pipeline:

```r
source("R_Scripts/3_merge_northern_non_northern_cpsr.R")
```

That script sources the rest of the chain automatically:

```
3_merge_northern_non_northern_cpsr.R      writes the final CSVs
└─ 2_get_non_northern_demographics_cpsr.R  StatCan WDS pull for non-northern ridings
   └─ 2_get_northern_demographics_cpsr.R   tongfen estimation for northern ridings
      ├─ 1_data_import.R                    imports & cleans 1999–2025 election results
      └─ 2_get_northern_populations.R       scrapes riding populations (elections.ontario.ca)
```

## Requirements

**R packages:** `here`, `tidyverse`, `readxl`, `knitr`, `kableExtra`, `sf`, `rvest`,
`cancensus`, `tongfen`.

```r
install.packages(c("here","tidyverse","readxl","knitr","kableExtra",
                   "sf","rvest","cancensus","tongfen"))
```

**cancensus API key** — required for the census pulls. Set it once:

```r
cancensus::set_cancensus_api_key("YOUR_KEY", install = TRUE)
# Recommended: point the cache somewhere OUTSIDE this repo
cancensus::set_cancensus_cache_path("YOUR_CACHE_FOLDER", install = TRUE)
```

**Network access** — the pipeline also fetches live data from `elections.on.ca` (1999–2014
results) and the Statistics Canada WDS, so it cannot run fully offline.

## Bundled data (`data/`)

These are the local inputs the scripts read; everything else is fetched at runtime.

- `on2018_results.xlsx`, `on2022_results.xlsx`, `on2025_results.csv` — provincial results
- `can_fedtable_final_20221005.RData` — federal electoral district lookup table
- `electoral_districts/ELECTORAL_DISTRICT.*` — current (2013) Ontario riding boundaries
- `electoral_districts/2012_ontario_ped/EO_107PD.*` — 2011 Ontario riding boundaries

## Notes

- `ED_ID` equals Elections Ontario's `ElectoralDistrictNumber` only for the 2013 federal
  redistribution (the boundaries used by the 2018/2022/2025 provincial elections). The final
  merge is deliberately restricted to those three elections for that reason.
- Extracted from the broader `laurentian_backlash` project.
