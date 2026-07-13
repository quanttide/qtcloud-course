"""GUI 自动化测试工具集 —— Xvfb 截图/OCR/窗口定位/智能点击。

依赖（缺失自动 skip，不报错）:
  - xvfb-run / Xvfb, xdotool, wmctrl
  - ImageMagick (import/convert), tesseract-ocr (chi_sim)
  - opencv-python-headless, numpy
"""

import os
import shutil
import signal
import subprocess
import time
from pathlib import Path

# ── 工具检测 ──────────────────────────────────────────────────────────


def check_tool(name: str) -> str | None:
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


def has_tesseract_cn() -> str | None:
    """检查 tesseract 是否支持简体中文。"""
    tess = check_tool("tesseract")
    if tess is None:
        return None
    r = subprocess.run(
        ["tesseract", "--list-langs"], capture_output=True, text=True, timeout=5,
    )
    return tess if "chi_sim" in (r.stdout + r.stderr) else None


def has_opencv() -> bool:
    try:
        import cv2  # noqa: F401
        return True
    except ImportError:
        return False


# ── Xvfb 生命周期 ─────────────────────────────────────────────────────


def xvfb_running(display: str) -> bool:
    """检查指定 display 上是否有 Xvfb 进程在运行。"""
    r = subprocess.run(
        ["ps", "-eo", "args"], capture_output=True, text=True, timeout=5,
    )
    return f"Xvfb {display}" in r.stdout


def ensure_xvfb(display: str = ":99", size: str = "1280x800x24") -> subprocess.Popen | None:
    """如无 Xvfb 则启动一个，返回进程句柄或 None（已有）。"""
    if xvfb_running(display):
        return None
    proc = subprocess.Popen(
        ["Xvfb", display, "-screen", "0", size,
         "+extension", "GLX", "-ac"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    time.sleep(0.5)
    return proc


# ── 窗口定位 ──────────────────────────────────────────────────────────


def find_window(display: str, *,
                patterns: tuple[str, ...] = (),
                class_pattern: str = "") -> str | None:
    """多方法回退查找窗口 ID。

    搜索顺序: xdotool search --name → --class → wmctrl → xwininfo。
    """
    env = {**os.environ, "DISPLAY": display}

    # 1) xdotool search --name
    if patterns:
        for name in patterns:
            wid = _xdotool_search("--name", name, env)
            if wid:
                return wid

    # 2) xdotool search --class
    if class_pattern:
        wid = _xdotool_search("--class", class_pattern, env)
        if wid:
            return wid

    # 3) wmctrl
    wid = _wmctrl_find(patterns + (class_pattern,) if class_pattern else patterns, env)
    if wid:
        return wid

    # 4) xwininfo -root -children
    keywords = list(patterns)
    if class_pattern:
        keywords.append(class_pattern)
    return _xwininfo_find(keywords, env)


def _xdotool_search(flag: str, pattern: str, env: dict) -> str | None:
    r = subprocess.run(
        ["xdotool", "search", flag, pattern],
        capture_output=True, text=True, timeout=5, env=env,
    )
    if r.returncode == 0 and r.stdout.strip():
        wid = r.stdout.strip().splitlines()[0]
        if wid != "0":
            return normalize_wid(wid)
    return None


def _wmctrl_find(patterns: tuple[str, ...], env: dict) -> str | None:
    if shutil.which("wmctrl") is None:
        return None
    r = subprocess.run(
        ["wmctrl", "-l"], capture_output=True, text=True, timeout=5, env=env,
    )
    for line in r.stdout.splitlines():
        parts = line.split(None, 3)
        if len(parts) >= 2 and parts[0] != "0x0":
            if len(parts) < 4:
                return parts[0]
            title = parts[3].lower()
            if any(p.lower() in title for p in patterns):
                return parts[0]
    # fallback: 第一个非根窗口
    for line in r.stdout.splitlines():
        wid = line.split(None, 1)[0]
        if wid != "0x0":
            return wid
    return None


def _xwininfo_find(keywords: list[str], env: dict) -> str | None:
    r = subprocess.run(
        ["xwininfo", "-root", "-children"],
        capture_output=True, text=True, timeout=5, env=env,
    )
    for line in r.stdout.splitlines():
        text = line.lower()
        if any(k.lower() in text for k in keywords):
            parts = line.strip().split()
            if parts:
                return parts[0]
    return None


def normalize_wid(wid: str) -> str:
    """统一窗口 ID 格式为 0x 前缀十六进制。
    xdotool 返回十进制，wmctrl/xwininfo 返回 0x 格式。
    """
    if wid.startswith("0x"):
        return wid
    try:
        return hex(int(wid))
    except ValueError:
        return wid


# ── XvfbApp 封装 ─────────────────────────────────────────────────────


class XvfbApp:
    """Xvfb 中启动 GUI 应用的生命周期管理。

    Usage::

        app = XvfbApp(binary="/path/to/app", bundle="/path/to/bundle")
        app.start(patterns=("MyApp",), class_pattern="my_app")
        assert app.window_id is not None
        # ... 测试 ...
        app.stop()
    """

    def __init__(self, binary: str | Path, bundle: str | Path,
                 display: str = ":99", size: str = "1280x800x24",
                 start_timeout: int = 15, render_delay: float = 2.0):
        self.binary = Path(binary)
        self.bundle = Path(bundle)
        self.display = display
        self.size = size
        self.start_timeout = start_timeout
        self.render_delay = render_delay
        self._proc: subprocess.Popen | None = None
        self._xvfb_proc: subprocess.Popen | None = None

    @property
    def env(self) -> dict:
        return {**os.environ, "DISPLAY": self.display}

    @property
    def window_id(self) -> str | None:
        if self._proc is None:
            return None
        return find_window(self.display,
                           patterns=(),
                           class_pattern=self._guess_class())

    def _guess_class(self) -> str:
        """从二进制名推断窗口类名。"""
        return self.binary.stem

    def start(self, *, patterns: tuple[str, ...] = (),
              class_pattern: str = "") -> None:
        """启动 Xvfb（需要时）+ 应用，等待窗口出现。"""
        self._xvfb_proc = ensure_xvfb(self.display, self.size)

        self._proc = subprocess.Popen(
            [str(self.binary)],
            cwd=str(self.bundle),
            env=self.env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )

        deadline = time.time() + self.start_timeout
        wid = None
        while time.time() < deadline:
            time.sleep(0.5)
            if self._proc.poll() is not None:
                out, err = self._proc.communicate()
                raise RuntimeError(
                    f"应用启动后崩溃\nstdout:\n{out.decode(errors='replace')}"
                    f"\nstderr:\n{err.decode(errors='replace')}"
                )
            wid = find_window(self.display, patterns=patterns,
                              class_pattern=class_pattern)
            if wid:
                break

        if not wid:
            self.stop()
            raise RuntimeError(f"窗口未在 {self.start_timeout}s 内出现")

        # 等首帧渲染
        time.sleep(self.render_delay)

    def stop(self) -> None:
        if self._proc and self._proc.poll() is None:
            self._proc.send_signal(signal.SIGTERM)
            try:
                self._proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._proc.kill()
        if self._xvfb_proc:
            self._xvfb_proc.kill()
            self._xvfb_proc = None


# ── 截图 & OCR ────────────────────────────────────────────────────────


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


# ── 智能点击 ──────────────────────────────────────────────────────────


def smart_click(label: str, window_id: str, display: str,
                *, cache_dir: str = "/tmp/widget-snaps",
                threshold: float = 0.7) -> bool:
    """智能点击：首屏 OCR 定位 → 缓存为模板 → 后续模板匹配。

    对应学习材料中的 smart_click 模式。
    Xvfb 无 WM 时截图整个 root 窗口，通过 OCR 在其中定位 UI 元素。
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
