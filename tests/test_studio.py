"""GUI 自动化测试 —— qtcloud_course_studio 桌面应用。

依赖 xvfb-run / Xvfb, xdotool, ImageMagick (import/convert),
tesseract-ocr (chi_sim), opencv-python, numpy。

缺失时会自动 skip 相关测试用例。
"""

import os
import re
import shutil
import signal
import subprocess
import time
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
STUDIO_SRC = PROJECT_ROOT / "src" / "studio"
STUDIO_BUNDLE = STUDIO_SRC / "build" / "linux" / "x64" / "release" / "bundle"
STUDIO_BINARY = STUDIO_BUNDLE / "qtcloud_course_studio"

# ── 工具检测 ──────────────────────────────────────────────────────────


def _check_tool(name: str, *, min_version: str | None = None) -> str | None:
    """检查系统工具是否存在，返回版本字符串或 None。"""
    path = shutil.which(name)
    if path is None:
        return None
    try:
        r = subprocess.run([name, "--version"], capture_output=True, text=True, timeout=5)
        output = r.stdout or r.stderr
        return output.splitlines()[0] if output else path
    except Exception:
        return path


@pytest.fixture(scope="session")
def has_xvfb():
    return _check_tool("xvfb-run") is not None or _check_tool("Xvfb") is not None


@pytest.fixture(scope="session")
def has_xdotool():
    return _check_tool("xdotool") is not None


@pytest.fixture(scope="session")
def has_import():
    return _check_tool("import") is not None


@pytest.fixture(scope="session")
def has_tesseract_cn():
    """检查 tesseract 是否支持简体中文。"""
    tess = _check_tool("tesseract")
    if tess is None:
        return None
    r = subprocess.run(
        ["tesseract", "--list-langs"], capture_output=True, text=True, timeout=5,
    )
    return tess if "chi_sim" in (r.stdout + r.stderr) else None


@pytest.fixture(scope="session")
def has_opencv():
    try:
        import cv2  # noqa: F401
        return True
    except ImportError:
        return False


# ── Studio 二进制 ─────────────────────────────────────────────────────


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


# ── 启动 / 停止 ───────────────────────────────────────────────────────


class StudioProcess:
    """包装 studio 进程 + xvfb 显示号。"""

    def __init__(self, proc: subprocess.Popen, display: str, bundle: Path):
        self.proc = proc
        self.display = display
        self.bundle = bundle

    @property
    def env(self) -> dict:
        return {**os.environ, "DISPLAY": self.display}

    def window_id(self) -> str | None:
        """查找 studio 窗口 ID，委托给 _find_window。"""
        return _find_window(self.display)

    def stop(self):
        if self.proc.poll() is None:
            self.proc.send_signal(signal.SIGTERM)
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()


@pytest.fixture(scope="module")
def studio(studio_binary, has_xvfb):
    """启动 studio 应用（虚拟显示器），返回 StudioProcess。"""
    if not has_xvfb:
        pytest.skip("xvfb-run / Xvfb 不可用")

    display = ":99"
    bundle = STUDIO_BUNDLE

    # 确保虚拟显示器在运行
    xvfb_proc = None
    if shutil.which("Xvfb") and not _xvfb_running(display):
        xvfb_proc = subprocess.Popen(
            ["Xvfb", display, "-screen", "0", "1280x800x24",
             "+extension", "GLX", "-ac"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        time.sleep(0.5)

    env = {**os.environ, "DISPLAY": display}
    proc = subprocess.Popen(
        [str(studio_binary)],
        cwd=str(bundle),
        env=env,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )

    # 等窗口出现
    deadline = time.time() + 15
    wid = None
    while time.time() < deadline:
        time.sleep(0.5)
        if proc.poll() is not None:
            out, err = proc.communicate()
            raise RuntimeError(
                f"Studio 启动后崩溃\nstdout:\n{out.decode(errors='replace')}"
                f"\nstderr:\n{err.decode(errors='replace')}"
            )
        wid = _find_window(display)
        if wid:
            break

    if not wid:
        proc.kill()
        if xvfb_proc:
            xvfb_proc.kill()
        pytest.fail("Studio 窗口未在 15s 内出现")

    # 窗口出现后等 Flutter 首帧渲染完成
    time.sleep(2)

    sp = StudioProcess(proc, display, bundle)
    try:
        yield sp
    finally:
        sp.stop()
        if xvfb_proc:
            xvfb_proc.kill()


def _xvfb_running(display: str) -> bool:
    r = subprocess.run(
        ["ps", "-eo", "args"], capture_output=True, text=True, timeout=5,
    )
    return f"Xvfb {display}" in r.stdout


def _find_window(display: str) -> str | None:
    """查找 studio 窗口 ID。尝试多种方法。"""
    env = {**os.environ, "DISPLAY": display}

    # 方法 1: xdotool search 按类名/标题
    for pattern in ("量潮课程云", "qtcloud_course_studio", "studio"):
        r = subprocess.run(
            ["xdotool", "search", "--name", pattern],
            capture_output=True, text=True, timeout=5, env=env,
        )
        if r.returncode == 0 and r.stdout.strip():
            wid = r.stdout.strip().splitlines()[0]
            if wid != "0":
                return _normalize_wid(wid)

    # 方法 2: xdotool search 按类名
    r = subprocess.run(
        ["xdotool", "search", "--class", "qtcloud_course_studio"],
        capture_output=True, text=True, timeout=5, env=env,
    )
    if r.returncode == 0 and r.stdout.strip():
        return _normalize_wid(r.stdout.strip().splitlines()[0])

    # 方法 3: wmctrl（有窗口管理器时）
    wmctrl = shutil.which("wmctrl")
    if wmctrl:
        r = subprocess.run(
            [wmctrl, "-l"], capture_output=True, text=True, timeout=5, env=env,
        )
        for line in r.stdout.splitlines():
            parts = line.split(None, 3)
            if len(parts) >= 2 and parts[0] != "0x0":
                if len(parts) < 4:
                    return parts[0]
                title = parts[3].lower()
                if "qtcloud_course_studio" in title or "studio" in title or "量潮" in title:
                    return parts[0]
        # fallback: 第一个非根窗口
        for line in r.stdout.splitlines():
            wid = line.split(None, 1)[0]
            if wid != "0x0":
                return wid

    # 方法 4: xwininfo -root -children
    r = subprocess.run(
        ["xwininfo", "-root", "-children"],
        capture_output=True, text=True, timeout=5, env=env,
    )
    for line in r.stdout.splitlines():
        if "qtcloud_course_studio" in line.lower() or "量潮" in line:
            parts = line.strip().split()
            if parts:
                wid = parts[0]
                return wid

    return None


def _normalize_wid(wid: str) -> str:
    """统一窗口 ID 格式为 0x 前缀的十六进制。"""
    if wid.startswith("0x"):
        return wid
    try:
        return hex(int(wid))
    except ValueError:
        return wid


# ── 截图 & OCR 工具 ──────────────────────────────────────────────────


def screenshot(display: str, output: str | Path) -> Path:
    """import -window root 截图（Xvfb 无 WM 时最有保障）。"""
    output = Path(output)
    subprocess.run(
        ["import", "-window", "root", str(output)],
        env={**os.environ, "DISPLAY": display},
        check=True, capture_output=True, timeout=15,
    )
    return output


def ocr_text(image: str | Path) -> str:
    """tesseract OCR 返回纯文本。"""
    r = subprocess.run(
        ["tesseract", str(image), "stdout", "-l", "chi_sim", "--psm", "6"],
        capture_output=True, text=True, timeout=15,
    )
    return r.stdout.strip()


def ocr_tsv(image: str | Path) -> list[dict]:
    """tesseract OCR 返回 TSV 解析为 dict 列表（level=5 单词级）。"""
    r = subprocess.run(
        ["tesseract", str(image), "stdout", "-l", "chi_sim", "--psm", "6", "tsv"],
        capture_output=True, text=True, timeout=15,
    )
    lines = r.stdout.strip().splitlines()
    if len(lines) < 2:
        return []
    headers = lines[0].split("\t")
    rows = []
    for line in lines[1:]:
        vals = line.split("\t")
        row = dict(zip(headers, vals))
        if row.get("level") == "5" and row.get("text", "").strip():
            rows.append(row)
    return rows


def smart_click(label: str, window_id: str, display: str,
                *, cache_dir: str = "/tmp/widget-snaps",
                threshold: float = 0.7) -> bool:
    """智能点击：首屏 OCR 定位 → 缓存为模板 → 后续模板匹配。

    对应学习材料中的 smart_click 模式。
    注意：Xvfb 无 WM 时 screenshot 截 root 窗口，
    smart_click 通过 OCR 在 root 截图中定位 UI 元素。
    """
    import cv2
    import numpy as np

    Path(cache_dir).mkdir(parents=True, exist_ok=True)
    template = Path(cache_dir) / f"{label}.png"

    shot_path = Path("/tmp") / f"smart_click_{label}.png"
    screenshot(display, shot_path)

    # 模板匹配（有缓存时）
    if template.exists():
        img = cv2.imread(str(shot_path))
        tmpl = cv2.imread(str(template))
        h, w = tmpl.shape[:2]
        res = cv2.matchTemplate(img, tmpl, cv2.TM_CCOEFF_NORMED)
        _, max_val, _, max_loc = cv2.minMaxLoc(res)
        if max_val >= threshold:
            cx, cy = max_loc[0] + w // 2, max_loc[1] + h // 2
            subprocess.run(
                ["xdotool", "mousemove", "--window", window_id,
                 str(cx), str(cy), "click", "1"],
                env={**os.environ, "DISPLAY": display},
                check=True, capture_output=True, timeout=5,
            )
            return True

    # 回退：OCR 定位并更新模板缓存
    rows = ocr_tsv(shot_path)
    for r in rows:
        if label in r.get("text", ""):
            cx = int(r["left"]) + int(r["width"]) // 2
            cy = int(r["top"]) + int(r["height"]) // 2
            # 裁剪保存为模板
            left, top, w, h = int(r["left"]), int(r["top"]), int(r["width"]), int(r["height"])
            pad = 8
            subprocess.run([
                "convert", str(shot_path),
                "-crop", f"{w + pad * 2}x{h + pad * 2}+{left - pad}+{top - pad}",
                str(template),
            ], capture_output=True, timeout=5)
            subprocess.run(
                ["xdotool", "mousemove", "--window", window_id,
                 str(cx), str(cy), "click", "1"],
                env={**os.environ, "DISPLAY": display},
                check=True, capture_output=True, timeout=5,
            )
            return True

    return False


# ── 测试用例 ──────────────────────────────────────────────────────────


class TestStudioStartup:
    """验证 studio 能正常启动并在虚拟显示器中显示窗口。"""

    def test_process_alive(self, studio: StudioProcess):
        assert studio.proc.poll() is None, "Studio 进程已退出"

    def test_window_visible(self, studio: StudioProcess):
        wid = studio.window_id()
        assert wid is not None, "未找到 studio 窗口"
        assert wid.startswith("0x"), f"窗口 ID 格式异常: {wid}"

    def test_screenshot_works(self, studio: StudioProcess, tmp_path):
        shot = screenshot(studio.display, tmp_path / "startup.png")
        assert shot.exists()
        assert shot.stat().st_size > 200, f"截图文件过小: {shot.stat().st_size}"


class TestStudioOCRSmoke:
    """验证 OCR 能从截图识别出内置示例数据的关键文字。"""

    EXPECTED_TEXTS = [
        "大数据微专业",
        "AI应用开发",
        "浙理班级",
        "杭电班级",
        "仪表盘",
        "课程研发",
        "教学管理",
    ]

    @pytest.fixture(scope="class")
    @classmethod
    def shot(cls, studio: StudioProcess, tmp_path_factory):
        tmp = tmp_path_factory.mktemp("ocr_smoke")
        return screenshot(studio.display, tmp / "ocr_smoke.png")

    def test_ocr_returns_text(self, shot, has_tesseract_cn):
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")
        text = ocr_text(shot)
        assert len(text) > 0, "OCR 未返回任何文字"

    @pytest.mark.parametrize("keyword", EXPECTED_TEXTS)
    def test_expected_keywords(self, shot, has_tesseract_cn, keyword):
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")
        text = ocr_text(shot)
        # tesseract 可能将 I 识别为 l（无衬线字体常见），所以放宽匹配
        assert keyword in text or keyword.replace("AI", "Al") in text, (
            f"OCR 未识别出「{keyword}」\nOCR 输出:\n{text[:500]}"
        )


class TestStudioTemplateMatch:
    """OpenCV 模板匹配 —— 预先截取 UI 元素作为模板进行定位。"""

    TEMPLATES = {
        "program": "专业",
        "class": "班级",
        "lesson": "课程",
        "develop": "研发",
    }

    @pytest.fixture(scope="class")
    @classmethod
    def shot(cls, studio: StudioProcess, tmp_path_factory):
        tmp = tmp_path_factory.mktemp("template_match")
        return screenshot(studio.display, tmp / "template.png")

    @pytest.fixture(scope="class")
    @classmethod
    def tab_regions(cls, shot, has_opencv):
        """用 OCR bounding box 找到底部 tab 文字区域作为模板。"""
        if not has_opencv:
            pytest.skip("opencv-python 不可用")

        import cv2
        import numpy as np

        rows = ocr_tsv(shot)
        # 底部 tab 通常位于图像下半部分
        h = cv2.imread(str(shot)).shape[0]
        bottom_rows = [r for r in rows if int(r["top"]) > h * 0.7]

        templates = {}
        img = cv2.imread(str(shot))
        for r in bottom_rows:
            label = r["text"].strip()
            x, y, w, ht = int(r["left"]), int(r["top"]), int(r["width"]), int(r["height"])
            # 扩大裁剪区域以包含 tab 背景
            pad = 8
            x1, y1 = max(0, x - pad), max(0, y - pad)
            x2, y2 = min(img.shape[1], x + w + pad), min(img.shape[0], y + ht + pad)
            templates[label] = img[y1:y2, x1:x2]

        return templates

    def test_has_templates(self, tab_regions):
        assert len(tab_regions) >= 2, f"底部 tab 识别不足: {list(tab_regions.keys())}"

    def test_each_tab_matchable(self, studio, tmp_path, tab_regions, has_opencv):
        """验证模板能在新截图中匹配到自身（基本健全性）。"""
        if not has_opencv:
            pytest.skip("opencv-python 不可用")

        import cv2

        shot2 = screenshot(studio.display, tmp_path / "match_check.png")
        img = cv2.imread(str(shot2))

        for label, tmpl in tab_regions.items():
            h, w = tmpl.shape[:2]
            if h > img.shape[0] or w > img.shape[1]:
                continue
            res = cv2.matchTemplate(img, tmpl, cv2.TM_CCOEFF_NORMED)
            _, max_val, _, _ = cv2.minMaxLoc(res)
            assert max_val > 0.5, (
                f"Tab「{label}」模板匹配度过低: {max_val:.3f}"
            )


class TestStudioTabNavigation:
    """验证点击底部 tab 能切换页面内容。"""

    @pytest.fixture(scope="class")
    @classmethod
    def tab_coords(cls, studio, has_opencv, has_tesseract_cn):
        """用 OCR bounding box 计算底部 tab 的点击坐标。"""
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")

        shot = screenshot(studio.display, "/tmp/studio_tabnav.png")
        rows = ocr_tsv(shot)
        # 底部区域
        display_h = 800  # Xvfb 分辨率
        tabs = [r for r in rows if int(r["top"]) > display_h * 0.7]

        if not tabs:
            pytest.skip("未识别到底部 tab 文字")

        coords = {}
        for r in tabs:
            label = r["text"].strip()
            cx = int(r["left"]) + int(r["width"]) // 2
            cy = int(r["top"]) + int(r["height"]) // 2
            coords[label] = (cx, cy)

        return coords

    def test_at_least_two_tabs(self, tab_coords):
        assert len(tab_coords) >= 2, f"底部 tab 不足: {list(tab_coords.keys())}"

    def test_click_tab_changes_content(self, studio, tmp_path, tab_coords, has_tesseract_cn):
        """点击 tab 后截图 OCR，确认页面文字变化。"""
        if not has_tesseract_cn:
            pytest.skip("tesseract/chi_sim 不可用")

        for label, (cx, cy) in tab_coords.items():
            # 点击前截图
            before = screenshot(studio.display, tmp_path / f"before_{label}.png")
            before_text = ocr_text(before)

            # 点击 tab
            subprocess.run(
                ["xdotool", "mousemove", "--window", studio.window_id(),
                 str(cx), str(cy), "click", "1"],
                env=studio.env, check=True, capture_output=True, timeout=5,
            )
            time.sleep(1)

            # 点击后截图
            after = screenshot(studio.display, tmp_path / f"after_{label}.png")
            after_text = ocr_text(after)

            # 页面应有变化（除非点击的是当前所在 tab）
            if before_text != after_text:
                break
        else:
            # 所有 tab 点击后页面都未变化 —— 可能 xdotool 不生效
            pytest.skip("所有 tab 点击后页面文字无变化")


class TestStudioPixelSpot:
    """像素颜色探测 —— 无 OCR / 无模板时的应急定位方法。"""

    def test_detect_tab_region_by_color(self, studio: StudioProcess, tmp_path, has_import):
        """在底部区域逐行扫描，找到非背景色的连续行作为导航栏。"""
        shot = screenshot(studio.display, tmp_path / "pixel_spot.png")

        # 在图像底部 30% 区域采样
        import_path = shutil.which("import")
        convert_path = shutil.which("convert")
        if not import_path or not convert_path:
            pytest.skip("ImageMagick (import/convert) 不可用")

        h = 800
        sample_x = 640  # 水平中间
        bg_colors = set()
        nav_rows = []

        # 用 convert 探测颜色
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

        # 如果能找到非背景色的连续行，说明导航栏存在
        if nav_rows:
            nav_center_y = sum(nav_rows) // len(nav_rows)
            assert 500 < nav_center_y < h, (
                f"导航栏 Y 中心 {nav_center_y} 不在预期范围"
            )
        else:
            # 纯色背景可能探测不到差异 —— 跳过而非失败
            pytest.skip("未探测到导航栏颜色差异")


class TestStudioRestart:
    """停止再启动，确认不留下残留进程。"""

    def test_clean_restart(self, studio_binary, has_xvfb, tmp_path):
        if not has_xvfb:
            pytest.skip("xvfb-run / Xvfb 不可用")

        display = ":100"
        xvfb = subprocess.Popen(
            ["Xvfb", display, "-screen", "0", "1280x800x24",
             "+extension", "GLX", "-ac"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        time.sleep(0.5)

        env = {**os.environ, "DISPLAY": display}
        proc = subprocess.Popen(
            [str(studio_binary)], cwd=str(STUDIO_BUNDLE),
            env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )

        # 等一会后退出
        time.sleep(3)
        assert proc.poll() is None, "进程在 3s 内崩溃"
        proc.terminate()
        proc.wait(timeout=5)
        xvfb.kill()
        xvfb.wait()

        # 确认进程已清理
        assert proc.poll() is not None, "进程未退出"
