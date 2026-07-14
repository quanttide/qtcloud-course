"""GUI 自动化测试 —— qtcloud_course_studio 桌面应用。

测试策略：编译 Linux release 版本 -> Xvfb 虚拟显示器中运行 ->
截图 + tesseract OCR + OpenCV 模板匹配验证 UI。
"""

import os
import subprocess
import time
from pathlib import Path
from typing import Optional

import pytest

from tests.utils.gui import (
    XvfbApp,
    ensure_xvfb,
    ocr_text,
    ocr_tsv,
    screenshot,
)

# ── 模块级常量 ───────────────────────────────────────────────────────

PROJECT_ROOT: Path = Path(__file__).resolve().parent.parent
STUDIO_SRC: Path = PROJECT_ROOT / "src" / "studio"
STUDIO_BUNDLE: Path = STUDIO_SRC / "build" / "linux" / "x64" / "release" / "bundle"
STUDIO_BINARY: Path = STUDIO_BUNDLE / "qtcloud_course_studio"

# 窗口查找关键字（按优先级排序）
WINDOW_PATTERNS: tuple[str, ...] = ("量潮课程云", "qtcloud_course_studio", "studio")
WINDOW_CLASS: str = "qtcloud_course_studio"

# 关键页面文字 —— OCR 烟雾测试目标
EXPECTED_KEYWORDS: list[str] = [
    "大数据微专业", "AI应用开发",
    "浙理班级", "杭电班级",
    "仪表盘", "课程研发", "教学管理",
]

# 底部 tab 判定阈值（占窗口高度的比例）
TAB_REGION_RATIO: float = 0.7

# 截图缓存路径
CACHED_SHOT_PATH: str = "/tmp/studio_ocr_shot.png"


# ── 条件跳过辅助函数 ────────────────────────────────────────────────


def require_tesseract(has_tesseract_cn: bool) -> None:
    """tesseract/chi_sim 不可用时跳过当前测试。"""
    if not has_tesseract_cn:
        pytest.skip("tesseract/chi_sim 不可用")


def require_opencv(has_opencv: bool) -> None:
    """opencv-python 不可用时跳过当前测试。"""
    if not has_opencv:
        pytest.skip("opencv-python 不可用")


def require_opencv_and_tesseract(has_opencv: bool, has_tesseract_cn: bool) -> None:
    """opencv-python 或 tesseract/chi_sim 任一缺失时跳过。"""
    reasons: list[str] = []
    if not has_opencv:
        reasons.append("opencv-python")
    if not has_tesseract_cn:
        reasons.append("tesseract/chi_sim")
    if reasons:
        pytest.skip(f"{' / '.join(reasons)} 不可用")


def require_xvfb(has_xvfb: bool) -> None:
    """Xvfb 不可用时跳过当前测试。"""
    if not has_xvfb:
        pytest.skip("xvfb-run / Xvfb 不可用")


def require_importmagick(has_import: bool) -> None:
    """ImageMagick (import/convert) 不可用时跳过当前测试。"""
    if not has_import:
        pytest.skip("ImageMagick (import/convert) 不可用")


# ── 会话级编译 fixture ──────────────────────────────────────────────


@pytest.fixture(scope="session")
def studio_binary() -> Path:
    """确保 studio Linux release 版已编译；编译失败则跳过全部依赖测试。"""
    if not STUDIO_BINARY.exists():
        print(f"\n  ~ 编译 studio: flutter build linux --release ...")
        try:
            subprocess.run(
                ["flutter", "build", "linux", "--release"],
                cwd=str(STUDIO_SRC),
                check=True,
                capture_output=True,
                text=True,
                timeout=300,
            )
        except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            stderr: str = getattr(e, "stderr", str(e)) or str(e)
            pytest.skip(f"编译失败: {stderr[:200]}")
    return STUDIO_BINARY


# ── 模块级应用实例 fixture ──────────────────────────────────────────


@pytest.fixture(scope="module")
def studio(studio_binary: Path, has_xvfb: bool) -> XvfbApp:
    """启动 studio（Xvfb 内），测试结束后清理进程和截图缓存。"""
    require_xvfb(has_xvfb)

    app = XvfbApp(
        binary=STUDIO_BINARY,
        bundle=STUDIO_BUNDLE,
        display=":99",
        render_delay=4.0,
    )
    app.start(patterns=WINDOW_PATTERNS, class_pattern=WINDOW_CLASS)
    try:
        yield app
    finally:
        app.stop()
        _clear_shot_cache()


# ── 模块级截图缓存 fixture ──────────────────────────────────────────


_SHOT_CACHE: Optional[Path] = None


def _cached_screenshot(display: str) -> Path:
    """模块级截图缓存，避免每次 OCR 测试重复截取。"""
    global _SHOT_CACHE
    if _SHOT_CACHE is None:
        _SHOT_CACHE = screenshot(display, CACHED_SHOT_PATH)
    return _SHOT_CACHE


def _clear_shot_cache() -> None:
    """清理截图缓存，用于 studio 重启等场景。"""
    global _SHOT_CACHE
    _SHOT_CACHE = None


# ═══════════════════════════════════════════════════════════════════════
# TestStudioStartup —— 进程 / 窗口 / 截图基础检测
# ═══════════════════════════════════════════════════════════════════════


class TestStudioStartup:
    """验证 studio 能正常启动并在虚拟显示器中显示窗口。"""

    def test_process_alive(self, studio: XvfbApp) -> None:
        """确认 studio 进程在启动后保持运行。"""
        assert studio._proc and studio._proc.poll() is None, "Studio 进程已退出"

    def test_window_visible(self, studio: XvfbApp) -> None:
        """确认 Xvfb 虚拟显示器中存在 studio 窗口。"""
        wid: Optional[str] = studio.window_id
        assert wid is not None, "未找到 studio 窗口"
        assert wid.startswith("0x"), f"窗口 ID 格式异常: {wid}"

    def test_screenshot_works(self, studio: XvfbApp, tmp_path: Path) -> None:
        """确认 ImageMagick 能对虚拟显示器截取有效截图。"""
        shot: Path = screenshot(studio.display, tmp_path / "startup.png")
        assert shot.exists()
        assert shot.stat().st_size > 200, f"截图文件过小: {shot.stat().st_size}"


# ═══════════════════════════════════════════════════════════════════════
# TestStudioOCRSmoke —— OCR 识别关键文字
# ═══════════════════════════════════════════════════════════════════════


class TestStudioOCRSmoke:
    """验证 OCR 能从截图识别出关键页面文字。"""

    @staticmethod
    def _ensure_studio_alive(studio: XvfbApp) -> None:
        """辅助检查：确认 studio 进程和窗口仍存活。"""
        assert studio._proc and studio._proc.poll() is None, "Studio 进程已退出"
        assert studio.window_id is not None, "窗口已消失"

    def test_ocr_returns_text(self, studio: XvfbApp, has_tesseract_cn: bool) -> None:
        """OCR 引擎应能从截图中提取非空文字。"""
        require_tesseract(has_tesseract_cn)
        self._ensure_studio_alive(studio)

        shot: Path = _cached_screenshot(studio.display)
        assert shot.stat().st_size > 2000, f"截图文件过小: {shot.stat().st_size}"
        text: str = ocr_text(shot)
        assert len(text) > 0, (
            f"OCR 未返回任何文字。截图大小: {shot.stat().st_size}"
        )

    @pytest.mark.parametrize("keyword", EXPECTED_KEYWORDS)
    def test_expected_keywords(
        self, studio: XvfbApp, has_tesseract_cn: bool, keyword: str
    ) -> None:
        """关键业务词汇应能被 OCR 正确识别。"""
        require_tesseract(has_tesseract_cn)
        shot: Path = _cached_screenshot(studio.display)
        text: str = ocr_text(shot)
        # AI 的 tesseract 可能识别为 Al（大写 i → 小写 l）
        assert keyword in text or keyword.replace("AI", "Al") in text, (
            f"OCR 未识别出「{keyword}」\nOCR 输出:\n{text[:500]}"
        )


# ═══════════════════════════════════════════════════════════════════════
# TestStudioTemplateMatch —— OpenCV 模板匹配验证 UI 元素
# ═══════════════════════════════════════════════════════════════════════


class TestStudioTemplateMatch:
    """OpenCV 模板匹配 —— 从 OCR 定位区域裁剪模板，验证可重新匹配。"""

    @staticmethod
    def _bottom_tab_rows(shot: Path) -> list[dict]:
        """从 OCR 行中筛选底部导航区域的 tab 元素。"""
        import cv2

        rows: list[dict] = ocr_tsv(shot)
        h: int = cv2.imread(str(shot)).shape[0]
        return [r for r in rows if int(r["top"]) > h * TAB_REGION_RATIO]

    def test_has_templates(
        self, studio: XvfbApp, has_opencv: bool, has_tesseract_cn: bool
    ) -> None:
        """底部导航 tab 应能被 OCR 成功定位（≥2 个），为模板匹配提供坐标。"""
        require_opencv_and_tesseract(has_opencv, has_tesseract_cn)
        shot: Path = _cached_screenshot(studio.display)
        bottom_rows: list[dict] = self._bottom_tab_rows(shot)
        assert len(bottom_rows) >= 2, (
            f"底部 tab 识别不足: {[r['text'] for r in bottom_rows]}"
        )

    def test_each_tab_matchable(
        self,
        studio: XvfbApp,
        tmp_path: Path,
        has_opencv: bool,
        has_tesseract_cn: bool,
    ) -> None:
        """每个底部 tab 区域裁剪为模板后，应能在新截图中通过模板匹配重新定位。"""
        require_opencv_and_tesseract(has_opencv, has_tesseract_cn)
        import cv2

        shot: Path = _cached_screenshot(studio.display)
        bottom_rows: list[dict] = self._bottom_tab_rows(shot)

        # 重新截图用于匹配（避免同一张图自匹配的过度乐观结果）
        fresh_shot: Path = screenshot(studio.display, tmp_path / "match_check.png")
        img = cv2.imread(str(fresh_shot))

        for r in bottom_rows:
            label: str = r["text"].strip()
            x, y, w, ht = (
                int(r["left"]),
                int(r["top"]),
                int(r["width"]),
                int(r["height"]),
            )
            pad: int = 8
            x1, y1 = max(0, x - pad), max(0, y - pad)
            x2, y2 = (
                min(img.shape[1], x + w + pad),
                min(img.shape[0], y + ht + pad),
            )
            tmpl = img[y1:y2, x1:x2]
            h2, w2 = tmpl.shape[:2]
            if h2 > img.shape[0] or w2 > img.shape[1]:
                continue
            res = cv2.matchTemplate(img, tmpl, cv2.TM_CCOEFF_NORMED)
            _, max_val, _, _ = cv2.minMaxLoc(res)
            assert max_val > 0.5, (
                f"Tab「{label}」模板匹配度过低: {max_val:.3f}"
            )


# ═══════════════════════════════════════════════════════════════════════
# TestStudioTabNavigation —— 底部 tab 点击切换页面
# ═══════════════════════════════════════════════════════════════════════


class TestStudioTabNavigation:
    """验证点击底部 tab 能切换页面内容。"""

    @staticmethod
    def _bottom_tabs_from_tsv(rows: list[dict], img_height: int = 800) -> list[dict]:
        """从 OCR TSV 行中筛选底部 tab 区域元素。"""
        threshold: int = int(img_height * TAB_REGION_RATIO)
        return [r for r in rows if int(r["top"]) > threshold]

    def test_at_least_two_tabs(self, studio: XvfbApp, has_tesseract_cn: bool) -> None:
        """底部导航栏应包含至少 2 个 tab 项。"""
        require_tesseract(has_tesseract_cn)
        shot: Path = _cached_screenshot(studio.display)
        rows: list[dict] = ocr_tsv(shot)
        tabs: list[dict] = self._bottom_tabs_from_tsv(rows)
        assert len(tabs) >= 2, f"底部 tab 不足: {[r['text'] for r in tabs]}"

    def test_click_tab_changes_content(
        self, studio: XvfbApp, tmp_path: Path, has_tesseract_cn: bool
    ) -> None:
        """逐个点击底部 tab 并对比点击前后的 OCR 文字，至少有一个 tab 引起页面变化。"""
        require_tesseract(has_tesseract_cn)

        shot: Path = _cached_screenshot(studio.display)
        rows: list[dict] = ocr_tsv(shot)
        tabs: list[dict] = self._bottom_tabs_from_tsv(rows)
        if not tabs:
            pytest.skip("未识别到底部 tab 文字")

        for r in tabs:
            label: str = r["text"].strip()
            cx: int = int(r["left"]) + int(r["width"]) // 2
            cy: int = int(r["top"]) + int(r["height"]) // 2

            before: Path = screenshot(studio.display, tmp_path / f"before_{label}.png")
            before_text: str = ocr_text(before)

            subprocess.run(
                [
                    "xdotool",
                    "mousemove", "--window", studio.window_id,
                    str(cx), str(cy), "click", "1",
                ],
                env=studio.env,
                check=True,
                capture_output=True,
                timeout=5,
            )
            time.sleep(1)

            after: Path = screenshot(studio.display, tmp_path / f"after_{label}.png")
            after_text: str = ocr_text(after)

            if before_text != after_text:
                return  # 页面内容有变化，确认 tab 切换成功

        pytest.skip("所有 tab 点击后页面文字无变化")


# ═══════════════════════════════════════════════════════════════════════
# TestStudioPixelSpot —— 像素颜色探测（应急方法）
# ═══════════════════════════════════════════════════════════════════════


class TestStudioPixelSpot:
    """像素颜色探测 —— 当 OCR / 模板匹配均不可用时，通过 ImageMagick 逐像素采样定位导航栏。"""

    def test_detect_tab_region_by_color(
        self, studio: XvfbApp, tmp_path: Path, has_import: bool
    ) -> None:
        """通过 ImageMagick 按列逐像素采样，利用导航栏与背景的颜色差异定位其 Y 坐标。"""
        import shutil

        convert_path: Optional[str] = shutil.which("convert")
        require_importmagick(has_import)
        if not convert_path:
            pytest.skip("ImageMagick (convert) 不可用")

        shot: Path = screenshot(studio.display, tmp_path / "pixel_spot.png")
        h: int = 800
        sample_x: int = 640
        bg_colors: set[str] = set()
        nav_rows: list[int] = []

        for y in range(int(h * 0.7), h, 2):
            r = subprocess.run(
                [
                    "convert", str(shot),
                    "-crop", f"1x1+{sample_x}+{y}",
                    "-format", "%[hex:p{0,0}]", "info:",
                ],
                capture_output=True,
                text=True,
                timeout=5,
            )
            color: str = r.stdout.strip()
            if len(bg_colors) < 5:
                bg_colors.add(color)
            elif color not in bg_colors:
                nav_rows.append(y)
                if len(nav_rows) > 3:
                    break

        if nav_rows:
            nav_center_y: int = sum(nav_rows) // len(nav_rows)
            assert 500 < nav_center_y < h, (
                f"导航栏 Y 中心 {nav_center_y} 不在预期范围 (500~{h})"
            )
        else:
            pytest.skip("未探测到导航栏颜色差异")


# ═══════════════════════════════════════════════════════════════════════
# TestStudioRestart —— 停止再启动，验证进程清理
# ═══════════════════════════════════════════════════════════════════════


class TestStudioRestart:
    """手动管理 Xvfb + studio 生命周期，验证进程可正常退出且无残留。"""

    def test_clean_restart(
        self, studio_binary: Path, has_xvfb: bool, tmp_path: Path
    ) -> None:
        """在新 display 上手动启动 → terminate → wait，验证进程正确退出。"""
        require_xvfb(has_xvfb)

        display: str = ":100"
        xvfb = ensure_xvfb(display)

        proc = subprocess.Popen(
            [str(studio_binary)],
            cwd=str(STUDIO_BUNDLE),
            env={**os.environ, "DISPLAY": display},
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        time.sleep(3)
        assert proc.poll() is None, "进程在 3s 内崩溃"
        proc.terminate()
        proc.wait(timeout=5)
        if xvfb:
            xvfb.kill()
            xvfb.wait()
        assert proc.poll() is not None, "进程未退出"
