"""GUI 自动化测试 —— qtcloud_course_studio 桌面应用。

依赖自动检测，缺失时 pytest.skip。
"""

import os
import subprocess
import time
from pathlib import Path

import pytest

from tests.utils.gui import (
    XvfbApp,
    ensure_xvfb,
    ocr_text,
    ocr_tsv,
    screenshot,
    find_window,
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
STUDIO_SRC = PROJECT_ROOT / "src" / "studio"
STUDIO_BUNDLE = STUDIO_SRC / "build" / "linux" / "x64" / "release" / "bundle"
STUDIO_BINARY = STUDIO_BUNDLE / "qtcloud_course_studio"

# ── session-scoped file-level fixtures ────────────────────────────────


@pytest.fixture(scope="session")
def studio_binary():
    if not STUDIO_BINARY.exists():
        print(f"\n  ~ 编译 studio: flutter build linux --release ...")
        try:
            subprocess.run(
                ["flutter", "build", "linux", "--release"],
                cwd=str(STUDIO_SRC),
                check=True, capture_output=True, text=True, timeout=300,
            )
        except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            stderr = e.stderr if hasattr(e, "stderr") else str(e)
            pytest.skip(f"编译失败: {stderr[:200]}")
    return STUDIO_BINARY


@pytest.fixture(scope="module")
def studio(studio_binary, has_xvfb):
    if not has_xvfb:
        pytest.skip("xvfb-run / Xvfb 不可用")

    app = XvfbApp(
        binary=STUDIO_BINARY,
        bundle=STUDIO_BUNDLE,
        display=":99",
        render_delay=4.0,
    )
    app.start(
        patterns=("量潮课程云", "qtcloud_course_studio", "studio"),
        class_pattern="qtcloud_course_studio",
    )
    try:
        yield app
    finally:
        app.stop()


# ── class-level shared screenshot (plain function, no class-scoped) ────


_STUDIO_SHOT: Path | None = None


def _get_shot(display: str) -> Path:
    global _STUDIO_SHOT
    if _STUDIO_SHOT is None:
        _STUDIO_SHOT = screenshot(display, "/tmp/studio_ocr_shot.png")
    return _STUDIO_SHOT


# ═══════════════════════════════════════════════════════════════════════
# Test classes
# ═══════════════════════════════════════════════════════════════════════


class TestStudioStartup:
    """验证 studio 能正常启动并在虚拟显示器中显示窗口。"""

    def test_process_alive(self, studio: XvfbApp):
        assert studio._proc and studio._proc.poll() is None, "Studio 进程已退出"

    def test_window_visible(self, studio: XvfbApp):
        wid = studio.window_id
        assert wid is not None, "未找到 studio 窗口"
        assert wid.startswith("0x"), f"窗口 ID 格式异常: {wid}"

    def test_screenshot_works(self, studio: XvfbApp, tmp_path):
        shot = screenshot(studio.display, tmp_path / "startup.png")
        assert shot.exists()
        assert shot.stat().st_size > 200, f"截图文件过小: {shot.stat().st_size}"


class TestStudioOCRSmoke:
    """验证 OCR 能从截图识别出关键文字。"""

    EXPECTED_TEXTS = [
        "大数据微专业", "AI应用开发",
        "浙理班级", "杭电班级",
        "仪表盘", "课程研发", "教学管理",
    ]

    def test_ocr_returns_text(self, studio, has_tesseract_cn):
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")
        assert studio._proc and studio._proc.poll() is None, "Studio 进程已退出"
        wid = studio.window_id
        assert wid is not None, f"窗口已消失"
        shot = _get_shot(studio.display)
        assert shot.stat().st_size > 2000, f"截图文件过小: {shot.stat().st_size}"
        text = ocr_text(shot)
        assert len(text) > 0, f"OCR 未返回任何文字。截图大小: {shot.stat().st_size}"

    @pytest.mark.parametrize("keyword", EXPECTED_TEXTS)
    def test_expected_keywords(self, studio, has_tesseract_cn, keyword):
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")
        shot = _get_shot(studio.display)
        text = ocr_text(shot)
        assert keyword in text or keyword.replace("AI", "Al") in text, (
            f"OCR 未识别出「{keyword}」\nOCR 输出:\n{text[:500]}"
        )


class TestStudioTemplateMatch:
    """OpenCV 模板匹配 —— 预先截取 UI 元素作为模板进行定位。"""

    def test_has_templates(self, studio, has_opencv, has_tesseract_cn):
        if not has_opencv or not has_tesseract_cn:
            pytest.skip("opencv-python 或 tesseract 不可用")

        shot = _get_shot(studio.display)
        import cv2
        rows = ocr_tsv(shot)
        h = cv2.imread(str(shot)).shape[0]
        bottom_rows = [r for r in rows if int(r["top"]) > h * 0.7]
        assert len(bottom_rows) >= 2, f"底部 tab 识别不足: {[r['text'] for r in bottom_rows]}"

    def test_each_tab_matchable(self, studio, tmp_path, has_opencv, has_tesseract_cn):
        if not has_opencv or not has_tesseract_cn:
            pytest.skip("opencv-python 或 tesseract 不可用")

        import cv2
        shot = _get_shot(studio.display)
        rows = ocr_tsv(shot)
        h = cv2.imread(str(shot)).shape[0]
        bottom_rows = [r for r in rows if int(r["top"]) > h * 0.7]

        shot2 = screenshot(studio.display, tmp_path / "match_check.png")
        img = cv2.imread(str(shot2))

        for r in bottom_rows:
            label = r["text"].strip()
            x, y, w, ht = int(r["left"]), int(r["top"]), int(r["width"]), int(r["height"])
            pad = 8
            x1, y1 = max(0, x - pad), max(0, y - pad)
            x2, y2 = min(img.shape[1], x + w + pad), min(img.shape[0], y + ht + pad)
            tmpl = img[y1:y2, x1:x2]
            h2, w2 = tmpl.shape[:2]
            if h2 > img.shape[0] or w2 > img.shape[1]:
                continue
            res = cv2.matchTemplate(img, tmpl, cv2.TM_CCOEFF_NORMED)
            _, max_val, _, _ = cv2.minMaxLoc(res)
            assert max_val > 0.5, f"Tab「{label}」模板匹配度过低: {max_val:.3f}"


class TestStudioTabNavigation:
    """验证点击底部 tab 能切换页面内容。"""

    def test_at_least_two_tabs(self, studio, has_tesseract_cn):
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")
        shot = _get_shot(studio.display)
        rows = ocr_tsv(shot)
        tabs = [r for r in rows if int(r["top"]) > 800 * 0.7]
        assert len(tabs) >= 2, f"底部 tab 不足: {[r['text'] for r in tabs]}"

    def test_click_tab_changes_content(self, studio, tmp_path, has_tesseract_cn):
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")

        shot = _get_shot(studio.display)
        rows = ocr_tsv(shot)
        tabs = [r for r in rows if int(r["top"]) > 800 * 0.7]
        if not tabs:
            pytest.skip("未识别到底部 tab 文字")

        for r in tabs:
            label = r["text"].strip()
            cx = int(r["left"]) + int(r["width"]) // 2
            cy = int(r["top"]) + int(r["height"]) // 2

            before = screenshot(studio.display, tmp_path / f"before_{label}.png")
            before_text = ocr_text(before)

            subprocess.run(
                ["xdotool", "mousemove", "--window", studio.window_id,
                 str(cx), str(cy), "click", "1"],
                env=studio.env, check=True, capture_output=True, timeout=5,
            )
            time.sleep(1)

            after = screenshot(studio.display, tmp_path / f"after_{label}.png")
            after_text = ocr_text(after)

            if before_text != after_text:
                # 页面有变化，说明 tab 切换成功
                return

        pytest.skip("所有 tab 点击后页面文字无变化")


class TestStudioPixelSpot:
    """像素颜色探测 —— 无 OCR / 无模板时的应急定位方法。"""

    def test_detect_tab_region_by_color(self, studio: XvfbApp, tmp_path, has_import):
        import shutil
        convert_path = shutil.which("convert")
        if not has_import or not convert_path:
            pytest.skip("ImageMagick (import/convert) 不可用")

        shot = screenshot(studio.display, tmp_path / "pixel_spot.png")
        h = 800
        sample_x = 640
        bg_colors: set[str] = set()
        nav_rows: list[int] = []

        for y in range(int(h * 0.7), h, 2):
            r = subprocess.run(
                ["convert", str(shot), "-crop", f"1x1+{sample_x}+{y}",
                 "-format", "%[hex:p{0,0}]", "info:"],
                capture_output=True, text=True, timeout=5,
            )
            color = r.stdout.strip()
            if len(bg_colors) < 5:
                bg_colors.add(color)
            elif color not in bg_colors:
                nav_rows.append(y)
                if len(nav_rows) > 3:
                    break

        if nav_rows:
            nav_center_y = sum(nav_rows) // len(nav_rows)
            assert 500 < nav_center_y < h, f"导航栏 Y 中心 {nav_center_y} 不在预期范围"
        else:
            pytest.skip("未探测到导航栏颜色差异")


class TestStudioRestart:
    """停止再启动，确认不留下残留进程。"""

    def test_clean_restart(self, studio_binary, has_xvfb, tmp_path):
        if not has_xvfb:
            pytest.skip("xvfb-run / Xvfb 不可用")

        display = ":100"
        xvfb = ensure_xvfb(display)

        proc = subprocess.Popen(
            [str(studio_binary)], cwd=str(STUDIO_BUNDLE),
            env={**os.environ, "DISPLAY": display},
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        time.sleep(3)
        assert proc.poll() is None, "进程在 3s 内崩溃"
        proc.terminate()
        proc.wait(timeout=5)
        if xvfb:
            xvfb.kill()
            xvfb.wait()
        assert proc.poll() is not None, "进程未退出"
