"""Verify the server starts and serves the API correctly."""

import json
import os
import socket
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

import pytest

from playwright.sync_api import Page

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SERVER_DIR = PROJECT_ROOT / "src/provider"
BINARY_DIR = SERVER_DIR / "bin"
BINARY_PATH = BINARY_DIR / "server"


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@pytest.fixture(scope="session")
def build():
    """构建服务端二进制文件，返回二进制路径。"""
    BINARY_DIR.mkdir(exist_ok=True)
    subprocess.run(
        ["go", "build", "-o", str(BINARY_PATH), "./cmd/server"],
        cwd=str(SERVER_DIR),
        check=True,
        capture_output=True,
        text=True,
    )
    return BINARY_PATH


def _start_server(binary: Path, *, video_dir: str | None = None) -> tuple:
    """启动服务端实例，返回 (base_url, proc)。"""
    host = "127.0.0.1"
    port = _free_port()
    base = f"http://{host}:{port}"

    env = os.environ.copy()
    env["LISTEN_ADDR"] = f"{host}:{port}"
    if video_dir is not None:
        env["VIDEO_DIR"] = video_dir

    proc = subprocess.Popen(
        [str(binary)],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    deadline = time.time() + 15
    ready = False
    while time.time() < deadline:
        try:
            resp = urllib.request.urlopen(f"{base}/healthz", timeout=1)
            if resp.status == 200:
                ready = True
                break
        except (urllib.error.URLError, ConnectionError, OSError):
            time.sleep(0.3)

    if not ready:
        proc.kill()
        raise RuntimeError(f"Server did not start within 15s on port {port}")

    return base, proc


def _stop_server(proc) -> None:
    proc.terminate()
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()


@pytest.fixture(scope="module")
def server(build):
    base, proc = _start_server(build)
    try:
        yield base, proc
    finally:
        _stop_server(proc)


def _req(method: str, url: str, data: bytes | None = None):
    req = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        resp = urllib.request.urlopen(req, timeout=5)
        return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


# ── Server health ──────────────────────────────────────────────────

class TestServerHealth:
    def test_starts_and_healthy(self, server):
        base, proc = server
        assert proc.poll() is None, "server process exited"

    def test_healthz(self, server):
        base, proc = server
        status, body = _req("GET", f"{base}/healthz")
        assert status == 200
        assert body == b'{"status":"ok"}'


# ── Program CRUD ───────────────────────────────────────────────────

class TestProgramCRUD:
    def test_list_empty(self, server):
        base, _ = server
        status, body = _req("GET", f"{base}/programs")
        assert status == 200
        data = json.loads(body)
        assert isinstance(data, list)

    def test_create(self, server):
        base, _ = server
        status, body = _req("POST", f"{base}/programs", '{"name":"prog-A"}'.encode())
        assert status == 201
        prog = json.loads(body)
        assert prog["name"] == "prog-A"
        assert "id" in prog

    def test_get_created(self, server):
        base, _ = server
        _, body = _req("POST", f"{base}/programs", '{"name":"prog-B"}'.encode())
        pid = json.loads(body)["id"]
        status, body = _req("GET", f"{base}/programs/{pid}")
        assert status == 200
        assert json.loads(body)["name"] == "prog-B"

    def test_update(self, server):
        base, _ = server
        _, body = _req("POST", f"{base}/programs", '{"name":"old"}'.encode())
        pid = json.loads(body)["id"]
        status, body = _req(
            "PUT", f"{base}/programs/{pid}",
            '{"name":"new","status":"published"}'.encode(),
        )
        assert status == 200
        assert json.loads(body)["name"] == "new"

    def test_delete(self, server):
        base, _ = server
        _, body = _req("POST", f"{base}/programs", '{"name":"to-delete"}'.encode())
        pid = json.loads(body)["id"]
        status, body = _req("DELETE", f"{base}/programs/{pid}")
        assert status == 204
        status, _ = _req("GET", f"{base}/programs/{pid}")
        assert status == 404


# ── Course → Phase → Lesson chain ──────────────────────────────────

class TestCoursePhaseLessonChain:
    def test_full_chain(self, server):
        base, _ = server

        _, body = _req("POST", f"{base}/courses", '{"name":"course-A"}'.encode())
        cid = json.loads(body)["id"]

        _, body = _req(
            "POST", f"{base}/phases",
            ('{"name":"phase-1","courseId":"' + cid + '","sortOrder":1}').encode(),
        )
        pid = json.loads(body)["id"]

        status, body = _req("GET", f"{base}/phases?courseId={cid}")
        assert status == 200
        assert len(json.loads(body)) == 1

        _, body = _req("POST", f"{base}/lessons", '{"title":"lesson-1","duration":45}'.encode())
        lid = json.loads(body)["id"]

        _, body = _req(
            "PUT", f"{base}/phases/{pid}",
            ('{"name":"phase-1","sortOrder":1,"lessonIds":["' + lid + '"]}').encode(),
        )
        assert lid in json.loads(body)["lessonIds"]

        _req("DELETE", f"{base}/phases/{pid}")
        status, _ = _req("GET", f"{base}/phases/{pid}")
        assert status == 404
        status, _ = _req("GET", f"{base}/lessons/{lid}")
        assert status == 200


# ── 404 ────────────────────────────────────────────────────────────

class TestNotFound:
    @pytest.mark.parametrize("method,url", [
        ("GET", "/programs/nonexistent"),
        ("PUT", "/programs/nonexistent"),
        ("DELETE", "/programs/nonexistent"),
        ("GET", "/courses/nonexistent"),
        ("GET", "/phases/nonexistent"),
        ("GET", "/lessons/nonexistent"),
        ("GET", "/scenes/nonexistent"),
        ("GET", "/classes/nonexistent"),
    ])
    def test_returns_404(self, server, method, url):
        base, _ = server
        body = '{"name":"x"}'.encode() if method == "PUT" else None
        status, _ = _req(method, f"{base}{url}", body)
        assert status == 404, f"{method} {url} expected 404, got {status}"


# ── Video serving ──────────────────────────────────────────────────

def _generate_test_video(path: Path) -> bool:
    """用 ffmpeg 生成 1 秒可播放的视频。返回 False 表示 ffmpeg 不可用。"""
    try:
        subprocess.run(
            ["ffmpeg", "-f", "lavfi", "-i", "color=c=black:s=320x240:d=1",
             "-c:v", "libx264", "-profile:v", "baseline", "-pix_fmt", "yuv420p",
             "-y", str(path)],
            capture_output=True, check=True, timeout=15,
        )
        return True
    except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        path.write_bytes(b"\x00\x00\x00\x18ftypmp42\x00\x00\x00\x00mp42mp41")
        return False


@pytest.fixture(scope="module")
def video_server(build, tmp_path_factory):
    video_dir = tmp_path_factory.mktemp("video")
    video_path = video_dir / "intro.mp4"
    has_ffmpeg = _generate_test_video(video_path)
    base, proc = _start_server(build, video_dir=str(video_dir))
    try:
        yield base, has_ffmpeg
    finally:
        _stop_server(proc)


class TestVideoServing:
    def test_serve_existing_file(self, video_server):
        base, _ = video_server
        status, body = _req("GET", f"{base}/video/intro.mp4")
        assert status == 200
        assert len(body) > 0

    def test_serve_nonexistent_file(self, video_server):
        base, _ = video_server
        status, _ = _req("GET", f"{base}/video/nonexistent.mp4")
        assert status == 404

    def test_content_type(self, video_server):
        """验证 Content-Type 为 video/mp4 — 对应 classroom.html 中 <source type="video/mp4">。"""
        base, _ = video_server
        req = urllib.request.Request(f"{base}/video/intro.mp4", method="GET")
        resp = urllib.request.urlopen(req, timeout=5)
        assert resp.status == 200
        ct = resp.headers.get("Content-Type", "")
        assert ct == "video/mp4", f"expected video/mp4, got {ct!r}"

    def test_range_request(self, video_server):
        """验证支持 HTTP Range 请求（206 Partial Content）— 浏览器 seek 依赖此能力。"""
        base, _ = video_server
        req = urllib.request.Request(
            f"{base}/video/intro.mp4",
            method="GET",
            headers={"Range": "bytes=0-1023"},
        )
        resp = urllib.request.urlopen(req, timeout=5)
        assert resp.status == 206, f"expected 206 Partial Content, got {resp.status}"
        body = resp.read()
        assert 0 < len(body) <= 1024, f"range response body length={len(body)}"
        content_range = resp.headers.get("Content-Range", "")
        assert content_range.startswith("bytes 0-"), (
            f"unexpected Content-Range: {content_range!r}"
        )
        assert "video/mp4" in resp.headers.get("Content-Type", "")


class TestVideoPlayability:
    def test_video_is_playable(self, video_server, tmp_path):
        base, has_ffmpeg = video_server
        if not has_ffmpeg:
            pytest.skip("ffmpeg not available, skipping playability check")

        # 下载视频
        _, body = _req("GET", f"{base}/video/intro.mp4")
        assert len(body) > 100, "downloaded video too small"

        # 写入临时文件供 ffprobe 分析
        tmp = tmp_path / "test.mp4"
        tmp.write_bytes(body)

        # 用 ffprobe 验证
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-print_format", "json",
             "-show_format", "-show_streams", str(tmp)],
            capture_output=True, text=True, timeout=10,
        )
        assert r.returncode == 0, f"ffprobe failed:\n{r.stderr}"

        info = json.loads(r.stdout)
        assert "mp4" in info["format"]["format_name"], (
            f"unexpected format: {info['format']['format_name']}"
        )
        duration = float(info["format"]["duration"])
        assert duration > 0, "video has zero duration"

        # 至少有一条视频流
        video_streams = [s for s in info.get("streams", []) if s["codec_type"] == "video"]
        assert len(video_streams) >= 1, "no video stream found"
        vs = video_streams[0]
        assert vs["codec_name"] == "h264", f"expected h264, got {vs['codec_name']}"
        assert "Baseline" in vs.get("profile", ""), (
            f"expected Baseline-family profile, got {vs.get('profile')}"
        )
        assert vs.get("width", 0) > 0, f"invalid width: {vs.get('width')}"
        assert vs.get("height", 0) > 0, f"invalid height: {vs.get('height')}"


class TestVideoBrowserPlayback:
    """在 headless 浏览器中实际播放视频，验证 oncanplay 事件。"""

    FIXTURES_DIR = Path(__file__).parent / "fixtures"

    def test_video_plays_in_browser(self, video_server, page: Page):
        base, has_ffmpeg = video_server
        if not has_ffmpeg:
            pytest.skip("ffmpeg not available, video may be invalid")

        # 用 ?url= 参数打开 classroom.html，注入服务端实际地址
        video_url = f"{base}/video/intro.mp4"
        html_path = self.FIXTURES_DIR / "classroom.html"
        page.goto(f"file://{html_path}?url={video_url}")

        # 等待 oncanplay 触发（浏览器需要下载并开始解码）
        page.wait_for_function(
            'document.getElementById("status").querySelector(".ok") !== null',
            timeout=10000,
        )

        # 验证分辨率已读取
        size_text = page.text_content("#size")
        assert "×" in (size_text or ""), f"unexpected size text: {size_text!r}"
