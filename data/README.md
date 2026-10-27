# 数据说明

`data/raw/` 和 `data/processed/` 里的文件**不会提交到 GitHub**（见 `.gitignore`），每位组员需要在本地自行下载或生成。这里只记录数据从哪里来、放在哪里、叫什么名字，保证大家本地的路径一致，脚本可以直接运行。

## 目录约定

| 目录 | 放什么 | 能否修改 |
|---|---|---|
| `data/raw/` | 从官方渠道下载的原始数据，保持原文件名 | 只读，不要手动改 |
| `data/processed/` | 由 `scripts/` 中脚本生成的清洗后数据 | 只由脚本写入，可随时删除重跑 |

## 数据来源

| 数据集 | 来源 | 本地路径 | 备注 |
|---|---|---|---|
| Origin-Destination Train（站点间 OD 客流，按月） | LTA DataMall，Dynamic Datasets → Passenger Volume by Origin Destination Train Stations | `data/raw/od_train/origin_destination_train_YYYYMM.csv` | 需要 DataMall AccountKey，只能下载最近 3 个月 |
| Passenger Volume by Train Stations（进出站客流） | LTA DataMall | `data/raw/station_volume/transport_node_train_YYYYMM.csv` | 同上 |
| MRT 站点位置 / 出入口 | LTA DataMall（Static Datasets → Train Station Exit Point 等） | `data/raw/spatial/` | 坐标系为 SVY21（EPSG:3414） |
| 土地利用（Master Plan Land Use） | data.gov.sg / URA Master Plan | `data/raw/spatial/` | |

> 新增数据集时，请在上表补一行，并在 PR 描述中说明。

## 密钥

DataMall 的 AccountKey 放在仓库根目录的 `.Renviron` 里（已被 `.gitignore` 忽略，**绝不要提交**）：

```
LTA_ACCOUNT_KEY=你的key
```

R 中用 `Sys.getenv("LTA_ACCOUNT_KEY")` 读取。

## 大文件怎么共享

原始 CSV 和 ArcGIS 地理数据库体积大，请通过小组网盘（OneDrive / Google Drive 等）共享，并把链接写在这里，不要放进 Git。
