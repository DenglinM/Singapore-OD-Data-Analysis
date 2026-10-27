# arcgis/

ArcGIS Pro 相关文件。

- 可以提交：工程文件 `.aprx`、工具箱 `.atbx`、模型 / Python 工具脚本、图层样式 `.lyrx`。
- 不要提交：文件地理数据库 `*.gdb/`、`Index/`、`.backups/`、`ImportLog/` 等缓存（已在 `.gitignore` 中忽略）。
- `.aprx` 是二进制文件，Git 无法合并。**同一时间只让一个人修改同一个 `.aprx`**，修改前在群里说一声，或者每人各用一个 `.aprx`（例如 `od_map_姓名.aprx`）。
- 工程里引用数据时尽量使用相对路径（Project → Options → General → 勾选 “Store relative pathnames to data sources”）。
- 导出的地图成品放到 `outputs/figures/`。
