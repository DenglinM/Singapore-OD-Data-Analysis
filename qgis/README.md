# qgis/

QGIS 工程和样式文件。QGIS 免费开源，所有组员都能使用。

主要分析在 R / RStudio 中完成（空间数据用 `sf` 包处理），QGIS 主要用于：查看和检查空间数据、手动核对站点位置、制作报告用的地图。

## 可以提交

- 工程文件。**建议保存为 `.qgs`**（Project → Save As 时选择 `.qgs`）：它是纯文本 XML，Git 能看出改了什么；默认的 `.qgz` 是压缩包，Git 无法比较和合并。
- 图层样式 `.qml`、打印布局模板 `.qpt`、处理模型 `.model3`。

## 不要提交

- 数据本身（Shapefile、GeoPackage、GeoJSON 等）放到 `data/raw/` 或 `data/processed/`，工程中引用它们即可。
- 备份文件 `*.qgs~` / `*.qgz~` 和 GeoPackage 临时文件（已在 `.gitignore` 中忽略）。

## 注意

- 路径使用相对路径：Project → Properties → General → Save paths 选 **Relative**（QGIS 默认就是相对路径）。这样别人克隆后打开工程，图层不会丢失。
- 坐标系统一使用 **SVY21 / Singapore TM（EPSG:3414）**。
- 即使是 `.qgs`，多人同时改同一个工程也容易冲突。修改前在群里说一声，或者每人用自己的工程文件（例如 `od_map_姓名.qgs`）。
- 导出的地图成品放到 `outputs/figures/`。
