# 用户 GeoJSON 与 OD 代码验证：2026-11-04

## 完整代码扫描与当前结果

已接入官方 Excel 的 213 条原始记录，以及 `config/station_reference_supplements.R` 中有官方出处的 6 条补充代码。扫描了本地 2020-01 至 2026-09 的 81 个月 train 和 81 个月 bus OD 文件。只提取代码，未计算客流加权覆盖率。原文件未修改。

当前输出：252 个标准化 MRT/LRT 代码 lookup 行（包括官方单线代码、观测到的换乘组合和少量未在 OD 中出现的代码）、5,205 个公交站代码行。MRT 按原始站名汇总仍为 188 站，其中 121 个确定 subzone、67 个跨区；95 个代码 lookup 行因此仍未解决。公交 5,201 个代码有 subzone，4 个区外点未解决。

OD 库中有 5,789 个唯一的“mode＋原始代码”组合。保留原始写法后的覆盖计数如下；它们包含被标准化到同一码的不同写法，因此不能当作物理车站数：

| mode | matched | unresolved_subzone | code_not_in_lookup |
| --- | ---: | ---: | ---: |
| train | 164 | 94 | 5 |
| bus | 5,431 | 4 | 91 |

公交 91 个原始代码写法在当前 2026 点位快照中没有对应记录，需核对历史停用/迁移站或数据问题，未自动按最近站替代。详情在 `od_unresolved_codes.csv`。

MRT 还有 4 种标准化代码问题，对应 5 种原始写法：

| 标准化代码 | 发现月份数 | 范围 | 原因 |
| --- | ---: | --- | --- |
| `BP14` | 4 | 202006—202211 | 当前官方表与出口点位均不含该码，需历史参考 |
| `DT1/PB6` | 7 | 202005—202408 | `PB6` 不在官方表，疑似拼写错误，未自动改成 BP6 |
| `EW16/NE3/TE1` | 1 | 202212 | 官方各代码指向不同车站，未自动改成 TE17 |
| `CE2/NS27/TE2` | 1 | 202212 | 官方各代码指向不同车站，未自动改成 TE20 |

按月明细是 `mrt_code_issues_by_month.csv`。同站复合代码中的 `-` 与 `/` 已统一，2026 年 `CC33/CC34` 和历史 `CE2/CE1` 均按有来源的名称连接。跨 MRT/LRT 的同名组合（如 NE17/PTC）明确记录两组 `source_station_keys`；只有两组出口都唯一落在同一 subzone 才自动赋值，仍有跨区就留空。

本次是允许未解决记录的诊断运行。严格模式仍会因上述问题停止，不表示全体 OD 已可无缺失地分析。两套模拟测试通过；实际输出的 station_code 与 bus_stop_code 均唯一。下一步须处理跨区归属、历史公交点位和上述原始代码问题。

## 首次空间预览记录

本次只读取用户原始文件，结果写到本地项目 `data/processed/spatial_join/`；数据不提交到 GitHub。

| 文件 | 记录 | 关键字段 | 读取 CRS |
| --- | ---: | --- | --- |
| `LTABusStop.geojson` | 5,205 | `BUS_STOP_NUM` | EPSG:4326 |
| `LTAMRTStationExitGEOJSON.geojson` | 613 | `STATION_NA`, `EXIT_CODE` | EPSG:4326 |
| `MasterPlan2019SubzoneBoundaryNoSeaGEOJSON.geojson` | 332 | `SUBZONE_C`, `SUBZONE_N` | EPSG:4326 |

统一转换到 EPSG:3414 后，用 `st_intersects()` 匹配点与 2019 subzone。

- 公交：5,201 个代码成功匹配，4 个区外点未匹配，详见 `bus_unresolved.csv`。
- MRT/LRT：613 个出口全部唯一匹配到一个 subzone；按站名汇总有 188 个站，121 个全部出口在同一 subzone，67 个出口跨 subzone。
- 67 个跨区站未自动选区，包括 Woodlands；应核实车站代表点或使用有依据的统一规则，不能任取第一个出口。详见 `mrt_station_names_unresolved.csv`。
- 出口文件没有车站线路代码。按站名的空间结果在 `mrt_station_name_subzone_lookup.csv`；代码模板在 `station_code_crosswalk_template.csv`。待补充 crosswalk 后再生成 OD-ready MRT lookup。
- 检查了本地 2020-01 train OD 的表头和样例：含 `ORIGIN_PT_CODE`, `DESTINATION_PT_CODE`，如 `BP4`, `EW31`，没有站名；train transport-node 文件有 `PT_CODE`，也没有站名。尚未进行全时期 OD 覆盖扫描。
- `MasterPlan2025PlanningAreaBoundaryNoSea.geojson` 是 2025 planning-area 层级，本步骤未使用。2019 subzone 文件本身已有 `PLN_AREA_N/C` 与 `REGION_N/C`，如需后续汇总应明确采用哪个年份。

复现预览（在项目根目录；替换数据目录）：

```r
Sys.setenv(AR5302_SPATIAL_DIR = "你的原始数据目录")
source("scripts/04_spatial_preview.R")
```

该预览允许缺失 crosswalk、待核查空间结果，且不扫描 OD。它不表示严格验证通过。最终补充 crosswalk 和待核查规则后，配置 `AR5302_OD_DIR` 并运行 `scripts/04_spatial_join.R`。

模拟集的回归测试 `Rscript tests/test_spatial_join.R` 同时通过，包括缺少 crosswalk 时仍能导出公交结果与 MRT 站名结果。
