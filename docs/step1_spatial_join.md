# STEP 1：MRT / Bus → 2019 Subzone

本步骤生成每个 OD 节点唯一一行的 subzone lookup，用于随后分别连接 OD 起点和终点。它不计算 OD 流量、不分摊到出口，也不把一个车站复制到多个 subzone。

## 当前可验证的范围

已检查仓库的 `R/od_io.R` 和三份 R Markdown：OD 端点列是 `ORIGIN_PT_CODE`、`DESTINATION_PT_CODE`，公交代码按字符读取；Parquet 位于 `data/processed/od_parquet/`。随后用户提供了本地 GeoJSON，已完成真实空间预览，结果见 [GeoJSON 运行记录](step1_geojson_validation.md)。MRT 尚缺站名与 OD 代码对照表，OD 全量覆盖尚未验证。

新增流程已通过模拟数据测试：同区多出口、重复出口、跨区出口、边界点、区外点、空几何、CRS 转换、同一公交代码多坐标、换乘站代码顺序、缺失代码、人工修订、真实文件读写、分块 OD 扫描，以及连接两端后 OD 行数/流量不变。真实数据运行前须核实文件字段和年份。

## 1. 准备输入

在 RStudio 打开项目 `.Rproj`。安装一次依赖：

```r
install.packages(c("sf", "readr"))
```

从小组共享盘或官方来源获取以下数据，保留原文件，放在 `data/raw/spatial/`：

| 输入 | 要求 |
| --- | --- |
| Master Plan **2019** Subzone Boundary | polygon；稳定且唯一的 subzone code 和名称 |
| Train Station Exit Point | POINT；出口所属车站名称或可靠标识 |
| Bus Stop | POINT 或坐标 CSV；公交站代码 |
| station_code_crosswalk.csv | 经核实的出口车站标识与 OD 车站代码对应关系 |

来源：[data.gov.sg](https://data.gov.sg/) 的 URA Master Plan 2019 subzone 数据、[LTA DataMall](https://datamall.lta.gov.sg/) 的出口与公交站数据。仓库 `data/README.md` 有小组共享盘链接。这里没有自动下载，也不需要在脚本中填写 AccountKey。

修改 `config/spatial_join.R` 的文件路径、图层名和字段名。示例字段名仅是占位约定，不能保证与你下载的版本一致。Shapefile 需要完整配套 `.shp/.shx/.dbf/.prj`；GeoPackage 若有多个图层，必须填写 `layer`。可这样检查：

当前默认配置已经适配用户提供的三份 GeoJSON 和实际字段，无需编辑 JSON 内容。将文件放到 `data/raw/spatial/`，或用 `Sys.setenv(AR5302_SPATIAL_DIR="你的数据文件夹路径")` 指向已有数据目录。`AR5302_OD_DIR` 可以单独指向已有 OD 文件夹；不需要移动或修改原始文件。

尚未准备好 station-code crosswalk 时，先运行 `source("scripts/04_spatial_preview.R")`。该预览导出按站名汇总的空间结果、公交 lookup 和待填写代码模板；明确跳过 OD 覆盖检查并允许待核查结果。严格验证仍运行 `04_spatial_join.R`。缺少 crosswalk 时，MRT 按代码的 lookup 只有列名，没有数据行；不要把它当作完成的 OD lookup。

现在也可以用官方代码表自动生成 crosswalk，无需手填：

```r
install.packages(c("sf", "readr", "readxl")) # 一次性
Sys.setenv(AR5302_SPATIAL_DIR = "你的 GeoJSON 所在文件夹",
           AR5302_OD_DIR = "你的 OD CSV 所在文件夹")
# 将官方压缩包里的 .xls 保存到以下默认位置，或设置 AR5302_STATION_REFERENCE。
# data/raw/reference/Train Station Codes and Chinese Names.xls
source("scripts/03_station_code_crosswalk.R")
source("scripts/04_spatial_join.R")
```

第一步读取 [LTA 官方代码 Excel](https://datamall.lta.gov.sg/content/dam/datamall/datasets/Geospatial/Train%20Station%20Codes%20and%20Chinese%20Names.zip)，并补充 `config/station_reference_supplements.R` 中有官方来源的少量新站代码。精确匹配英文站名，MRT/LRT 同名站按代码类型分别处理，跨不同站名的复合代码拒绝自动连接。只为实际出现且全部代码指向同一站的 OD 复合代码生成别名。生成结果与代码审计保存在 `data/processed/spatial_join_inputs/`，主配置自动使用它们；手动 crosswalk 可通过 `AR5302_STATION_CROSSWALK` 指定。

首次会扫描所有本地月度 train/bus OD 文件，只提取两端的唯一代码，并按文件路径、大小、修改时间缓存。后续运行复用未改变的文件扫描结果。如果用户替换文件却刻意保留大小和修改时间，应删除 `od_code_cache.rds` 后重建。新增/删除文件后先重跑 `03_station_code_crosswalk.R` 刷新清单，再运行空间连接。所有原始文件保持不变。

```r
sf::st_layers("data/raw/spatial/your_file.gpkg")
x <- sf::st_read("data/raw/spatial/your_file.gpkg", layer = "your_layer")
names(x)
sf::st_crs(x)
```

空间文件按自身 CRS 元数据读取，统一转换到 SVY21 / EPSG:3414；缺少 CRS 时停止，不按文件名猜测。坐标 CSV 显式设置 `x/y/crs`，经纬度为 `x=Longitude, y=Latitude, crs=4326`。请核实 x/y 顺序、CRS 和坐标来源。

**边界年份固定为 2019，但车站/出口/公交站数据年份应覆盖研究期。** 最新公交数据可能没有 2020 年停用的站，最新轨道数据可能包含后期开通站。缺失会进入覆盖检查；不要为了消除报错直接删掉历史 OD。必要时补充适用年份的历史节点数据后重跑。本版一个代码对应一个固定地点，不处理同一公交代码在不同时期迁移；若发现迁移，应按时期分别配置输入、输出目录并生成 lookup。

## 2. 车站代码对照表

出口文件通常提供站名，OD 使用代码；二者不能直接连接。创建本地 `data/raw/spatial/station_code_crosswalk.csv`，格式如下（仅示意，不是完整站表）：

```csv
station_key,station_code
JURONG EAST,NS1/EW24
```

`station_key` 必须对应配置中 `mrt$key` 字段的值；只统一大小写及空白，不自动删除 MRT 后缀或模糊匹配。可以先导出待填写的车站列表：

```r
source("R/spatial_join.R")
source("config/spatial_join.R")
exits <- read_spatial_input(spatial_config$mrt, point = TRUE)
keys <- sort(unique(normalise_station_key(exits[[spatial_config$mrt$key]])))
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(data.frame(station_key = keys, station_code = ""),
                 "data/processed/station_code_crosswalk_template.csv")
```

核实后填入代码，并另存到配置的 `crosswalk` 路径。不要直接用空白模板运行。

- 先检查 OD 两端实际出现的代码。`NS1/EW24`、`EW24/NS1` 与完整代码构成的 `EW24-NS1` 排序后视为同一代码。
- 若 OD 还单独出现 `NS1` 或 `EW24`，只有核实它们确实代表同一车站后，才为该 `station_key` 增加相应行；脚本不会拆分复合代码自动推断别名。
- 不同 OD 别名可以指向同一车站；同一代码不能指向两个车站。
- 官方证实同名且 OD 复合代码包含 MRT/LRT 两套线路时，自动脚本会建立明确的出口组组合，并保存 `source_station_keys`。组合的全部出口同区才赋值，不任意选择 MRT 或 LRT 那一组。
- 全网内部 `node` 编号或 GIS 行号不一定是 LTA OD 代码，不能未经验证就用于连接。
- 公交代码统一为五位字符，如 `1012 → 01012`；非数字或超过五位的代码报错，原始数据不改写。

## 3. 运行

```r
source("scripts/04_spatial_join.R")
```

也可以在项目根目录执行：

```text
Rscript scripts/04_spatial_join.R
Rscript tests/test_spatial_join.R
```

可用环境变量 `AR5302_SPATIAL_CONFIG` 指向另一份配置。输入只读，重复运行会覆盖指定输出目录中本流程的结果。配置、运行环境也保存到该目录，以便复现。

默认从 `data/raw/OD/` 分块扫描全部匹配命名的月度 CSV，只保留两端唯一代码；文件较多时仍需扫描全部行。可以在配置中明确选择研究月份，覆盖结论仅适用于所选文件。

如果只保留了 Parquet，可在现有 R Markdown 环境导出小型代码清单，并设置 `od_files = character()`、`od_inventory = "data/processed/od_node_codes.csv"`：

```r
# 需要原项目已有的 here, arrow, dplyr；只 collect 唯一代码。
source(here::here("R", "od_io.R"))
od <- open_od()
# 如只研究部分月份，在这里先 filter(YYYYMM %in% ...)。
origin <- od |>
  dplyr::select(MODE, ORIGIN_PT_CODE) |>
  dplyr::distinct() |> dplyr::collect()
destination <- od |>
  dplyr::select(MODE, DESTINATION_PT_CODE) |>
  dplyr::distinct() |> dplyr::collect()
codes <- unique(rbind(
  data.frame(mode = origin$MODE, pt_code = origin$ORIGIN_PT_CODE),
  data.frame(mode = destination$MODE, pt_code = destination$DESTINATION_PT_CODE)))
readr::write_csv(codes, "data/processed/od_node_codes.csv")
```

没有 OD 清单时会明确提示 coverage NOT CHECKED；默认 `strict=TRUE, require_od_coverage=TRUE` 会在输出检查表后停止。用于仅检查空间输入时，可显式设 `require_od_coverage=FALSE`，但这不能证明与 OD 代码完整对齐。

## 4. 匹配规则与检查

使用 `sf::st_intersects()` 保留点命中的所有 polygon，与 [sf 空间连接文档](https://r-spatial.github.io/sf/reference/st_join.html) 中的空间谓词一致。polygon 先执行 `st_make_valid()`；code 缺失或重复时停止，需要先核实/按 code 合并，而不是任意取第一行。边界上的点可能命中两个区，会标记为 ambiguous，不选择第一个结果，也不自动找最近区。

同一车站的精确重复坐标先去重。全部出口均唯一匹配且属于同一 subzone 时自动赋值。只要有出口未匹配、在边界上，或出口跨 subzone，车站的最终 subzone 留空。该策略保守，不把“出口最多的区”当作真实车站位置。公交同一代码若有不同坐标，也留待核查。

输出位于 `data/processed/spatial_join/`：

| 文件 | 内容 |
| --- | --- |
| `mrt_station_subzone_lookup.csv` | 每个标准化 `station_code` 一行 |
| `bus_stop_subzone_lookup.csv` | 每个五位 `bus_stop_code` 一行 |
| `mrt_exit_matches.csv`, `bus_point_matches.csv` | 所有空间命中；`source_row` 为输入记录的 1-based 行号 |
| `mrt_duplicate_points.csv`, `bus_duplicate_points.csv` | 同一标识的重复坐标记录 |
| `mrt_keys_without_codes.csv` | 有出口但没填入 crosswalk 的车站 |
| `mrt_unresolved.csv`, `bus_unresolved.csv` | 未解决的最终节点 |
| `od_code_coverage.csv` | 原始及标准化 OD 代码，是否可连接 |
| `validation_summary.csv` | 各项数量；不是客流加权覆盖率 |

lookup 包含 `subzone_code/name`、`boundary_year`、`match_status`、`join_ready`、点数和候选区。**只有 `join_ready=TRUE` 的记录才能赋予 subzone。** 未解决记录仍保留在 lookup，不能因文件已导出而视为全部通过。

默认严格模式在存在未解决节点、遗漏的出口站名或 OD 代码时停止，但会先保存上述检查表。查看明细与地图，优先修正源文件选择和 crosswalk。对于确实跨区或边界位置的站，可依据有来源的站厅/主站位置等一致规则人工确定，并记录理由。不要将跨区出口数量解释为旅客分布。

人工修订文件可设为 `data/raw/spatial/subzone_overrides.csv`（数据文件不提交 Git）：

```csv
mode,node_code,subzone_code,reason
```

每行填 `train` 或 `bus`、lookup 中已有代码、有效 subzone code、核实理由/依据。配置 `overrides` 指向该文件后重跑；结果标记为 `manual_override`，并保留 `override_reason`，逐出口空间检查表仍保留原始匹配结果。修订不能新增未识别的 OD 代码，须先修正 crosswalk 或补齐节点数据。

## 5. 连接 OD 两端

可以在现有 R Markdown 中，在选定月份并 `collect()` 后添加以下代码。保留原始 OD 端点列，另建连接用的标准化代码。使用唯一 lookup 的 `match()` 不会因多个出口而复制客流：

```r
source("R/spatial_join.R")
lookup <- read_text_csv("data/processed/spatial_join/mrt_station_subzone_lookup.csv")
stopifnot(!anyDuplicated(lookup$station_code), all(lookup$join_ready == "TRUE"))
x <- od_train_2024 # 替换为当前研究月份的 OD 表
n_before <- nrow(x)
trips_before <- sum(x$TOTAL_TRIPS)
x$origin_code_join <- normalise_node_code(x$ORIGIN_PT_CODE, "train")
x$destination_code_join <- normalise_node_code(x$DESTINATION_PT_CODE, "train")
x$origin_subzone <- lookup$subzone_code[match(x$origin_code_join, lookup$station_code)]
x$destination_subzone <- lookup$subzone_code[match(x$destination_code_join, lookup$station_code)]
stopifnot(!anyNA(x$origin_subzone), !anyNA(x$destination_subzone),
          nrow(x) == n_before, sum(x$TOTAL_TRIPS) == trips_before)
```

公交同理，改用公交 lookup、`bus_stop_code` 和 `mode="bus"`。读取导出的代码 CSV 时保持字符类型，避免 Excel 等工具去掉前导零。随后才能按 `origin_subzone`、`destination_subzone` 聚合客流。
