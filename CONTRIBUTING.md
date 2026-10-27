# Contributing guide

The `main` branch of this repository is protected: **you cannot push directly to `main`**. Every change is merged through a pull request (PR) and needs approval from at least one teammate.

## 1. First-time setup

1. Accept the repository invitation (check the email linked to your GitHub account, or click Accept at <https://github.com/notifications>).
2. Install Git and set your name and email (matching your GitHub account):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your-github-email@example.com"
   ```
3. Clone the repository:
   ```bash
   git clone https://github.com/DenglinM/Singapore-OD-Data-Analysis.git
   ```
   Or in RStudio: File → New Project → Version Control → Git, and paste the URL above.
   If you prefer not to use the command line, [GitHub Desktop](https://desktop.github.com/) has a button for every step below.

## 2. Day-to-day workflow

```
update main → create a branch → edit and commit → push the branch → open a PR → review → merge → delete the branch
```

### 1. Before you start, sync the latest main

```bash
git checkout main
git pull
```

### 2. Create a branch for the task

One branch per task, named `type/short-description`:

| Prefix | Use | Example |
|---|---|---|
| `feat/` | new analysis or feature | `feat/od-reliability-check` |
| `fix/` | bug fix | `fix/station-code-mismatch` |
| `docs/` | documentation, report | `docs/meeting-2026-10-27` |
| `data/` | data-processing pipeline | `data/clean-od-202609` |

```bash
git checkout -b feat/od-reliability-check
```

### 3. Edit and commit

Commit in small steps, one change per commit:

```bash
git add scripts/03_reliability_check.R
git commit -m "Add consistency check between OD data and station tap-in/out volumes"
```

Write the commit message as one sentence describing what you did. Run `git status` before committing and **make sure no data files are included**.

### 4. Push the branch and open a PR

```bash
git push -u origin feat/od-reliability-check
```

Open the repository page and click the "Compare & pull request" button that appears. Then:

- give the PR a clear title describing what it does;
- fill in the description template (what changed, how you checked it, anything to watch out for);
- pick a teammate under Reviewers on the right.

### 5. Review

The reviewer reads the changes on the PR's "Files changed" tab and can comment on individual lines. When done, click "Review changes" and choose:

- **Approve**: looks good, ready to merge;
- **Request changes**: something needs fixing. The author keeps committing and pushing to the same branch, and the PR updates automatically.

What to look for: does the code run, are paths relative, are the results sensible, and were any large files or secrets committed by mistake.

### 6. Merge and clean up

Once approved, the PR author clicks **Squash and merge**, then "Delete branch". Locally:

```bash
git checkout main
git pull
git branch -d feat/od-reliability-check
```

## 3. Handling merge conflicts

If the PR says "This branch has conflicts", someone else changed the same lines:

```bash
git checkout main
git pull
git checkout your-branch
git merge main
# open the conflicted files, keep the correct content, remove the <<<<<<< ======= >>>>>>> markers
git add conflicted-file
git commit
git push
```

If you're unsure, ask in the group chat or go through it together with the teammate who changed the same lines.

**Preventing conflicts**: `git pull` before you start; when splitting work, give each person different scripts; several people editing the same QGIS project at once easily causes conflicts, so only one person should edit it at a time (see `qgis/README.md`).

## 4. Rules at a glance

- ✅ Every change goes through a PR and is merged after at least one review.
- ✅ Use relative paths (`here::here()`), never absolute paths from your own computer.
- ✅ Update `data/README.md` when you add a dataset.
- ❌ Do not commit raw data, large files (> 50 MB), `.RData` or secrets (`.Renviron`).
- ❌ Do not force-push (`git push --force`) to someone else's branch.

## 5. Splitting up tasks

Track tasks with GitHub **Issues**: open one issue per task and assign an owner. Write `Closes #<number>` in the PR description and the issue closes automatically when the PR is merged. You can also set up a board on the Projects page (To do / In progress / Done) to track progress.
