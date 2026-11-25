#!/usr/bin/env bash
# 课件预览同步：把 profile 仓里的课件搬进 src/lite/public/preview/，随 lite 一起构建上站。
#
# 单一事实源在 profile 仓（quanttide-profile-of-course-development），本脚本只搬运、不改写。
# 搬哪些目录由 src/lite/src/courses.ts 的 material 字段推出（取路径首段），避免两处清单漂移。
#
# 用法：CI 在 vite build 前执行；本地想让「预览课件」链接可用，也跑一次。
#   ./scripts/sync-material.sh
set -euo pipefail

REPO="${PROFILE_REPO:-quanttide/quanttide-profile-of-course-development}"
BRANCH="${PROFILE_BRANCH:-main}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COURSES="$ROOT/src/lite/src/courses.ts"
DEST="$ROOT/src/lite/public/preview"

mapfile -t DIRS < <(grep -oE "material: '[^']+'" "$COURSES" | sed -E "s/^material: '([^']+)'$/\1/" | cut -d/ -f1 | sort -u)
if [ "${#DIRS[@]}" -eq 0 ]; then
  echo "courses.ts 里没有 material 字段，无需同步"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$TMP/profile"

rm -rf "$DEST"
mkdir -p "$DEST"
for d in "${DIRS[@]}"; do
  if [ ! -d "$TMP/profile/$d" ]; then
    echo "警告：profile 仓里没有 $d，跳过" >&2
    continue
  fi
  cp -R "$TMP/profile/$d" "$DEST/$d"
  # 仓内文档不上站（README / AGENTS / CONTRIBUTING 等）
  find "$DEST/$d" -name '*.md' -delete
done

echo "已同步课件 → ${DEST#"$ROOT"/}"
find "$DEST" -type f | sed "s|$ROOT/||" | sort
