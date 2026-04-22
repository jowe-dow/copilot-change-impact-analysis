#!/usr/bin/env bash
#
# get-changed-files.sh
#
# 获取当前分支相对于基准分支（默认 master）的变更文件列表。
# 仅保留 src/ 下的前端源文件，排除生成文件和静态资源目录。
#
# 用法：
#   bash .github/skills/change-impact-analysis/scripts/get-changed-files.sh \
#     [base_branch] [src_dir] [extra_excludes...]
#
# 参数：
#   base_branch    基准分支名（默认：master）
#   src_dir        源码目录（默认：src）
#   extra_excludes 额外排除的目录名（空格分隔，可多个）
#
# 示例：
#   # 只用默认值
#   bash get-changed-files.sh
#
#   # 指定 develop 分支，排除 src/generated/ 和 src/types/
#   bash get-changed-files.sh develop src generated types
#
# 输出：
#   每行一个变更文件路径（workspace 相对路径）
#
# 内置排除规则（始终生效）：
#   - assets/    — 静态资源（图片、字体等）
#   - client/    — 自动生成的 API 客户端（如 openapi-generator 产物）
#   - __generated__/ — 常见生成代码目录
#   - node_modules/  — 依赖目录（通常不在 src/ 下，但做双保险）
#
# 如需完全自定义排除规则，直接修改此脚本的 BUILTIN_EXCLUDES 数组。
#

set -euo pipefail

BASE_BRANCH="${1:-master}"
SRC_DIR="${2:-src}"

# 内置排除目录（相对于 SRC_DIR）
BUILTIN_EXCLUDES=("assets" "client" "__generated__" "node_modules")

# 额外排除（来自命令行参数 $3、$4、...）
if [ $# -ge 3 ]; then
  EXTRA_EXCLUDES=("${@:3}")
else
  EXTRA_EXCLUDES=()
fi

# 确保我们在 git 仓库中
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "错误：当前目录不在 git 仓库中" >&2
  exit 1
fi

# 获取 merge-base（防止本地基准分支过旧）
MERGE_BASE=$(git merge-base HEAD "origin/${BASE_BRANCH}" 2>/dev/null \
  || git merge-base HEAD "${BASE_BRANCH}" 2>/dev/null \
  || echo "")

if [ -z "$MERGE_BASE" ]; then
  echo "错误：无法找到与 ${BASE_BRANCH} 的公共祖先。请先执行 git fetch origin ${BASE_BRANCH}" >&2
  exit 1
fi

# 构建 grep 排除参数
EXCLUDE_ARGS=()
for dir in "${BUILTIN_EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(-e "^${SRC_DIR}/${dir}/")
done
if [ ${#EXTRA_EXCLUDES[@]} -gt 0 ]; then
  for dir in "${EXTRA_EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=(-e "^${SRC_DIR}/${dir}/")
  done
fi

# 获取变更文件（包括新增 A、修改 M、重命名 R 的目标）
# 先过滤排除目录，再过滤只保留前端源文件扩展名
git diff --name-only --diff-filter=AMR "$MERGE_BASE" HEAD -- "${SRC_DIR}/" \
  | grep -v "${EXCLUDE_ARGS[@]}" \
  | grep -E '\.(ts|tsx|js|jsx|vue|svelte)$' \
  || true

