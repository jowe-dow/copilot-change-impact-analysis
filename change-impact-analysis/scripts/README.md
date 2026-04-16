# 脚本说明

## 文件列表

| 脚本 | 用途 | 运行方式 |
|------|------|---------|
| `get-changed-files.sh` | 获取当前分支 vs master 的变更文件列表 | `bash get-changed-files.sh [base_branch]` |

## get-changed-files.sh

### 参数
- `[base_branch]` — 基准分支名，默认 `master`

### 过滤规则
- 仅分析 `src/` 下的文件
- 排除 `src/client/` 和 `src/assets/`
- 仅包含 `.ts/.tsx/.js/.jsx/.vue` 文件
- 使用 `git merge-base` 确定比较起点

### 依赖
- Git（需要 `origin/<base_branch>` 引用，先 `git fetch` 确保最新）
