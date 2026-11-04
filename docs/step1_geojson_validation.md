# 用户 GeoJSON 空间预览：2026-11-04

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
