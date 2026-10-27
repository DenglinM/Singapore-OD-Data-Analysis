# Singapore MRT OD Data Analysis

基于新加坡公共交通（MRT）起讫点（Origin-Destination, OD）客流数据，结合站点、土地利用等空间数据开展分析，目标是：

1. 检验 OD 数据的可靠性；
2. 挖掘有研究价值的主题（例如站点土地利用与客流的关系）。

主要工具：**R / RStudio**，部分空间分析使用 **ArcGIS Pro**。

## 仓库结构

```
.
├── data/
│   ├── raw/            # 原始数据（不提交到 Git，见 data/README.md）
│   ├── processed/      # 脚本生成的中间数据（不提交）
│   └── README.md       # 数据来源、下载方式、文件命名约定
├── scripts/            # 按编号顺序运行的分析脚本 01_*.R, 02_*.R ...
├── R/                  # 可复用的 R 函数
├── arcgis/             # ArcGIS Pro 工程 (.aprx)、工具箱、样式
├── outputs/
│   ├── figures/        # 图表、地图成品
│   └── tables/         # 结果表格（小文件）
├── docs/               # 研究设计、会议记录、报告草稿
├── CONTRIBUTING.md     # 小组协作流程（必读）
└── Singapore-OD-Data-Analysis.Rproj
```

## 快速开始

1. 克隆仓库：
   ```bash
   git clone https://github.com/DenglinM/Singapore-OD-Data-Analysis.git
   ```
2. 用 RStudio 打开 `Singapore-OD-Data-Analysis.Rproj`（保证工作目录是项目根目录）。
3. 按 [`data/README.md`](data/README.md) 下载数据，放到 `data/raw/` 对应位置。
4. 按编号顺序运行 `scripts/` 中的脚本。

## 关于数据文件

**原始数据和大文件不要提交到 GitHub。** OD 数据每月数百 MB，GitHub 单文件上限 100 MB，而且仓库一旦进了大文件，就算之后删除，历史记录里仍然存在，每个人克隆都会变慢。`.gitignore` 已经忽略了 `data/raw/`、`data/processed/`、压缩包和 ArcGIS 地理数据库；大文件请用小组网盘共享，并把链接写在 `data/README.md`。

## 协作方式

请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。简要来说：`main` 分支受保护，所有修改都通过 **新建分支 → 提交 → Pull Request → 组员审阅 → 合并** 完成。

## 许可

[MIT](LICENSE)
