# scripts/

分析脚本，按执行顺序编号，从上到下依次运行即可复现全部结果：

```
01_download_data.R     # 下载 / 整理原始数据到 data/raw/
02_clean_od.R          # 清洗 OD 数据 → data/processed/
03_reliability_check.R # 数据可靠性检验
04_spatial_join.R      # 与站点、土地利用等空间数据连接
05_analysis_*.R        # 各研究主题的分析
```

约定：

- 用 RStudio 打开根目录的 `Singapore-OD-Data-Analysis.Rproj`，路径一律写相对于项目根目录的路径（推荐 `here::here("data", "raw", ...)`），不要写 `C:/Users/...` 这样的绝对路径。
- 脚本只从 `data/` 读数据，只向 `data/processed/` 和 `outputs/` 写结果。
- 可复用的函数放到 `R/` 目录，在脚本开头 `source()`。
- 每个脚本开头用注释写清楚：作者、用途、输入、输出。
