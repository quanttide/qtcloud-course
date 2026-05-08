#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
STUDIO_BIN="$PROJECT_DIR/src/studio/build/linux/x64/release/bundle/qtcloud_course_studio"
VIDEO_OUT="$PROJECT_DIR/assets/videos/studio.mp4"

WINFO_FILE="/tmp/qtcloud_course_win.txt"

cleanup() {
  echo ""
  echo "Stopping..."
  pkill -f "qtcloud_course_studio" 2>/dev/null || true
  pkill -f "ffmpeg.*x11grab" 2>/dev/null || true
  xdotool mousemove 0 0 2>/dev/null || true
  rm -f "$WINFO_FILE"
}
trap cleanup EXIT

cleanup
sleep 1

echo "Starting studio..."
"$STUDIO_BIN" &
sleep 4

WID=$(xdotool search --name "量潮课程云" 2>/dev/null | tail -1)
if [ -z "$WID" ]; then
  echo "ERROR: Cannot find content window" >&2
  exit 1
fi
echo "Content Window ID: $WID"
xdotool getwindowgeometry "$WID"
echo "Window name: $(xdotool getwindowname "$WID")"

eval "$(xdotool getwindowgeometry --shell "$WID")"
echo "CONTENT_X=$X CONTENT_Y=$Y CONTENT_W=$WIDTH CONTENT_H=$HEIGHT"
echo "$X $Y $WIDTH $HEIGHT" > "$WINFO_FILE"

xdotool windowactivate --sync "$WID"
xdotool windowraise "$WID"
sleep 1
xdotool windowactivate --sync "$WID"
xdotool windowraise "$WID"
sleep 1

echo "Recording window area to $VIDEO_OUT..."
ffmpeg -y -f x11grab -video_size "${WIDTH}x${HEIGHT}" -i ":0.0+${X},${Y}" \
  -framerate 30 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" \
  -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p "$VIDEO_OUT" &
FFMPEG_PID=$!
sleep 2

xdotool windowactivate --sync "$WID"
xdotool windowraise "$WID"
sleep 0.5

# Window layout (1280x720 default):
#   AppBar: 56px top
#   Content: 56px ~ 640px
#   Bottom NavigationBar: 80px (640 ~ 720)
# Bottom nav items (3 items, evenly spaced):
#   X centers: ~213, ~640, ~1067
#   Y center: ~680
NAV_Y=$((HEIGHT - 40))
NAV1_X=$((WIDTH / 6))
NAV2_X=$((WIDTH / 2))
NAV3_X=$((5 * WIDTH / 6))

click_win() {
  xdotool windowactivate --sync "$WID" 2>/dev/null || true
  xdotool mousemove --window "$WID" "$1" "$2" click 1
  sleep "$3"
}

# ===== Demo walkthrough =====

# --- 1. Dashboard (default) ---
sleep 2

# --- 2. Switch to 课程研发 ---
click_win "$NAV2_X" "$NAV_Y" 2

# --- 3. Expand first program ---
click_win 200 150 1
sleep 1

# --- 4. Switch to 教学管理 ---
click_win "$NAV3_X" "$NAV_Y" 2

# --- 5. Click first class to show detail ---
click_win 200 200 1
sleep 2

# --- 6. Return to Dashboard ---
click_win "$NAV1_X" "$NAV_Y" 2

# Move mouse away
xdotool mousemove --window "$WID" 1200 700
sleep 1

echo "Stopping recording..."
kill "$FFMPEG_PID" 2>/dev/null || true
sleep 2

echo "Done! Video saved to $VIDEO_OUT"
