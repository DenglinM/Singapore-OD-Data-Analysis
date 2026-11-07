# Bus stops by URA urban centre (CBD, regional and sub-regional centres)

How `R/urban_centres.R` and `scripts/04_classify_bus_stops.R` decide which bus stops belong to the CBD, the Central Area and Singapore's decentralised commercial centres.

## Is there an official list of bus stop codes per centre?

No. Neither URA nor LTA publishes bus stop codes by centre, and URA does not release GIS boundaries for regional, sub-regional or fringe centres. The only official boundaries we can use are the URA Master Plan 2019 planning areas and subzones. The classification is therefore built by spatial intersection, as described below.

## Official definitions used

| Level | Official definition | Source |
|---|---|---|
| CBD | URA has no separate "CBD" boundary. We use the **Downtown Core** planning area (Raffles Place, Tanjong Pagar, Cecil, Marina Centre, Bayfront, City Hall, Bugis ...), which is the commercial core of URA's city centre ("Downtown"). | URA Master Plan 2019 planning areas |
| Central Area | The 11 planning areas URA groups as the Central Area: Downtown Core, Marina East, Marina South, Museum, Newton, Orchard, Outram, River Valley, Rochor, Singapore River, Straits View. | [Central Area (NLB Curiocity)](https://curiocity.nlb.gov.sg/story-maps/central-area), [Central Area, Singapore (Wikipedia)](https://en.wikipedia.org/wiki/Central_Area,_Singapore); URA [Master Plan 2025 regional plans](https://www.ura.gov.sg/land-planning/master-plan/master-plan-2025/regional-plans/) treat the "Central Area" as its own plan |
| Regional centres | "regional centres at **Woodlands**, **Jurong Lake District**, and **Tampines**" | URA, [Decentralisation](https://www.ura.gov.sg/land-planning/planning-strategies/decentralisation/) |
| Sub-regional centres | "sub-regional centres (e.g. **Bishan**, **Serangoon**, **Paya Lebar**)". Bishan was added in the Draft Master Plan 2025. | URA, [Decentralisation](https://www.ura.gov.sg/land-planning/planning-strategies/decentralisation/); [EdgeProp, DMP 2025: Bishan is the newest sub-regional centre](https://www.edgeprop.sg/property-news/draft-master-plan-2025-bishan-newest-sub-regional-centre) |
| Fringe centres | "fringe centres (e.g. **Newton**, **Novena**)" | URA, [Decentralisation](https://www.ura.gov.sg/land-planning/planning-strategies/decentralisation/) |

URA writes "e.g." for sub-regional and fringe centres, so these lists are the centres URA names, not necessarily a closed list. Older plans also mention Seletar as a future regional centre and Buona Vista (one-north) as a sub-regional centre; they are not in URA's current list and are left out. Add a row to `urban_centres` in `R/urban_centres.R` if the group wants them.

## Method

All layers are projected to SVY21 / Singapore TM (EPSG:3414).

1. **CBD and Central Area (official boundaries).** Each bus stop is joined to the MP2019 subzone polygon it falls in, which gives its planning area. `in_cbd` = planning area is Downtown Core; `in_central_area` = planning area is one of the 11 above.
2. **Regional, sub-regional and fringe centres (approximated).** Each centre is anchored on the MRT station at its core. The station's position is the centroid of its exits in LTA's MRT Station Exit dataset. A bus stop belongs to a centre if it is within `radius_m` (default **800 m**, about a 10-minute walk) of the anchor station. If two buffers overlap (Newton and Novena), the stop goes to the nearer station.

   | Centre | Type | Anchor station |
   |---|---|---|
   | Woodlands Regional Centre | Regional | Woodlands |
   | Jurong Lake District | Regional | Jurong East |
   | Tampines Regional Centre | Regional | Tampines |
   | Bishan | Sub-regional | Bishan |
   | Serangoon | Sub-regional | Serangoon |
   | Paya Lebar | Sub-regional | Paya Lebar |
   | Newton | Fringe | Newton |
   | Novena | Fringe | Novena |

3. **Final class (`zone_class`).** The highest level wins: CBD > Central Area (non-CBD) > Regional centre > Sub-regional centre > Fringe centre > Other. Stops with no subzone are the cross-border stops in Johor Bahru and are labelled "Outside Singapore". Because Newton is itself a Central Area planning area, Newton stops inside that planning area are labelled Central Area; `centre_name` still records Newton.

4. **Sensitivity check (`in_centre_subzone`).** Some centres have an MP2019 subzone with the same name (Woodlands Regional Centre; Jurong Gateway and Lakeside for Jurong Lake District; Bishan East; Serangoon Central; Newton Circus). The flag is TRUE when a stop lies in one of those subzones. Tampines, Paya Lebar and Novena have no matching subzone, which is why the buffer is the main method. These subzones are much smaller than an 800 m buffer (the "Woodlands Regional Centre" subzone is about 0.6 km² around Woodlands MRT), so the flag picks out the core of each centre.

## Output columns (`data/processed/bus_stop_centres.csv`)

| Column | Meaning |
|---|---|
| `bus_stop_code` | 5-character text with leading zeros, joins with `ORIGIN_PT_CODE` / `DESTINATION_PT_CODE` |
| `loc_desc` | LTA stop description |
| `zone_class` | Final class (see step 3) |
| `centre_name`, `centre_type` | Centre whose buffer the stop is in, else empty |
| `in_cbd`, `in_central_area` | Official planning-area flags |
| `in_centre_subzone` | Sensitivity flag (step 4) |
| `nearest_centre`, `dist_to_centre_m` | Nearest anchor station and straight-line distance, for testing other radii |
| `planning_area`, `subzone`, `region` | MP2019 subzone attributes |

## Preview result (800 m)

Run with LTA's Bus Stop Location of November 2024 (5,166 stops):

| zone_class | Stops |
|---|---|
| CBD | 83 |
| Central Area (non-CBD) | 148 |
| Regional centre | 113 (Woodlands 42, Tampines 40, Jurong Lake District 31) |
| Sub-regional centre | 101 (Serangoon 46, Paya Lebar 29, Bishan 26) |
| Fringe centre | 29 (Novena 22, Newton 7) |
| Other | 4,668 |
| Outside Singapore | 5 |

Counts change slightly with the bus stop file's date and with `radius_m`.

## Limitations

- The 800 m buffer is a planning convention, not a URA boundary. Try 500 m or 1,000 m with `classify_bus_stops(radius_m = ...)` to check the results are robust.
- Planning areas are large: Downtown Core includes some non-office land (e.g. Marina Centre hotels and malls).
- URA's "e.g." lists for sub-regional and fringe centres are not exhaustive.
