#!/usr/bin/env bash
# 课件同步：把 profile 仓里的课件按站内路径搬进 src/lite/public/，随 lite 一起构建上站。
#
# 单一事实源在 profile 仓（quanttide-profile-of-course-development），本脚本只搬运、不改写。
# 搬哪些由 src/lite/src/courses.ts 的 material 字段决定（profile 相对路径）；
# 落位规则与 courses.ts 的 materialHref() 一致：
#   material: <目录>/hello-world.html                    → courses/<目录>/lessons/hello-world.html
#   material: <目录>/phaseX/lessonN-slug/lesson-N-plan.html → courses/<目录>/lessons/<lessonN-slug>.html
# 课件里的 assets/ 是相对引用，跟着搬到 lessons/ 下。
#
# 用法：CI 在 vite build 前执行；本地想让「预览课件」链接可用，也跑一次。
#   ./scripts/sync-material.sh
set -euo pipefail

REPO="${PROFILE_REPO:-quanttide/quanttide-profile-of-course-development}"
BRANCH="${PROFILE_BRANCH:-main}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COURSES="$ROOT/src/lite/src/courses.ts"
DEST="$ROOT/src/lite/public"

mapfile -t MATERIALS < <(grep -oE "material: '[^']+'" "$COURSES" | sed -E "s/^material: '([^']+)'$/\1/" | sort -u)
if [ "${#MATERIALS[@]}" -eq 0 ]; then
  echo "courses.ts 里没有 material 字段，无需同步"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$TMP/profile"

rm -rf "$DEST/courses"
for m in "${MATERIALS[@]}"; do
  if [ ! -f "$TMP/profile/$m" ]; then
    echo "警告：profile 仓里没有 $m，跳过" >&2
    continue
  fi
  dir="${m%%/*}"
  depth="$(awk -F/ '{print NF}' <<< "$m")"
  if [ "$depth" -gt 2 ]; then
    lesson="$(basename "$(dirname "$m")")"   # 嵌套课时：取课时目录名
  else
    lesson="$(basename "$m" .html)"          # 平铺课件：取文件名
  fi
  out="$DEST/courses/$dir/lessons"
  mkdir -p "$out"
  cp "$TMP/profile/$m" "$out/$lesson.html"

  assets="$TMP/profile/$(dirname "$m")/assets"
  if [ -d "$assets" ]; then
    rm -rf "$out/assets"
    cp -R "$assets" "$out/assets"
  fi
  echo "  $m → courses/$dir/lessons/$lesson.html"
done

echo "已同步课件 → ${DEST#"$ROOT"/}/courses"
find "$DEST/courses" -type f | sed "s|$DEST/||" | sort
