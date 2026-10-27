# 小组协作指南

本仓库的 `main` 分支受保护：**不能直接 push 到 `main`**，所有修改都要通过 Pull Request（PR）合并，并且至少需要一位组员审阅通过。

## 一、第一次使用

1. 接受仓库邀请（查看 GitHub 注册邮箱，或在 <https://github.com/notifications> 里点 Accept）。
2. 安装 Git，并设置姓名和邮箱（与 GitHub 账号一致）：
   ```bash
   git config --global user.name "你的名字"
   git config --global user.email "你的GitHub邮箱"
   ```
3. 克隆仓库：
   ```bash
   git clone https://github.com/DenglinM/Singapore-OD-Data-Analysis.git
   ```
   也可以在 RStudio 中：File → New Project → Version Control → Git，粘贴上面的地址。
   不熟悉命令行的同学可以用 [GitHub Desktop](https://desktop.github.com/)，下面每一步都有对应按钮。

## 二、日常工作流程

```
更新 main → 新建分支 → 修改并提交 → 推送分支 → 开 PR → 审阅 → 合并 → 删除分支
```

### 1. 开始工作前，先同步最新的 main

```bash
git checkout main
git pull
```

### 2. 为这次任务新建分支

一个任务一个分支，分支名用 `类型/简短描述`：

| 前缀 | 用途 | 例子 |
|---|---|---|
| `feat/` | 新的分析或功能 | `feat/od-reliability-check` |
| `fix/` | 修复错误 | `fix/station-code-mismatch` |
| `docs/` | 文档、报告 | `docs/meeting-2026-10-27` |
| `data/` | 数据处理流程 | `data/clean-od-202609` |

```bash
git checkout -b feat/od-reliability-check
```

### 3. 修改并提交

小步提交，每次提交做一件事：

```bash
git add scripts/03_reliability_check.R
git commit -m "新增 OD 数据与进出站客流的一致性检验"
```

提交信息用一句话说明“做了什么”，中英文都可以。提交前用 `git status` 检查一下，**确认没有把数据文件加进去**。

### 4. 推送分支并开 PR

```bash
git push -u origin feat/od-reliability-check
```

打开仓库网页，会出现 “Compare & pull request” 按钮，点击后：

- 标题写清楚这次做了什么；
- 按模板填写描述（改了什么、怎么验证、有没有需要注意的地方）；
- 右侧 Reviewers 选一位组员。

### 5. 审阅（Review）

审阅人在 PR 的 “Files changed” 页面查看修改，可以逐行评论。看完后点 “Review changes”：

- **Approve**：没问题，可以合并；
- **Request changes**：需要修改。作者在同一分支上继续提交并 push，PR 会自动更新。

审阅重点：代码能否运行、路径是否为相对路径、结果是否合理、有没有误提交大文件或密钥。

### 6. 合并并清理

审阅通过后，由 PR 作者点击 **Squash and merge**，然后点 “Delete branch”。本地：

```bash
git checkout main
git pull
git branch -d feat/od-reliability-check
```

## 三、遇到冲突怎么办

如果 PR 提示 “This branch has conflicts”，说明别人也改了同一处：

```bash
git checkout main
git pull
git checkout 你的分支
git merge main
# 打开冲突文件，保留正确的内容，删掉 <<<<<<< ======= >>>>>>> 标记
git add 冲突文件
git commit
git push
```

拿不准就在群里问，或者请改了同一处的组员一起看。

**预防冲突**：开工前先 `git pull`；分工时尽量每人负责不同的脚本；QGIS 工程文件多人同时修改容易冲突，同一时间只让一个人改（见 `qgis/README.md`）。

## 四、规则汇总

- ✅ 所有修改走 PR，至少 1 人审阅后合并。
- ✅ 路径用相对路径（`here::here()`），不写个人电脑上的绝对路径。
- ✅ 新增数据集时更新 `data/README.md`。
- ❌ 不提交原始数据、大文件（> 50 MB）、`.RData`、密钥（`.Renviron`）。
- ❌ 不在别人的分支上强制推送（`git push --force`）。

## 五、任务分工建议

用 GitHub 的 **Issues** 记录任务：每个任务开一个 Issue 并指派负责人，PR 描述里写 `Closes #编号`，合并后 Issue 会自动关闭。也可以在 Projects 页面建一个看板（To do / In progress / Done）跟踪进度。
