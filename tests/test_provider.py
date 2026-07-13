"""Verify the server starts and serves the API correctly."""

import json
import os
import socket
import subprocess
import time
import urllib.error
import urllib.request

import pytest

SERVER_DIR = "src/provider"


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@pytest.fixture(scope="module")
def server():
    host = "127.0.0.1"
    port = _free_port()
    base = f"http://{host}:{port}"

    env = os.environ.copy()
    env["LISTEN_ADDR"] = f"{host}:{port}"
    proc = subprocess.Popen(
        ["go", "run", "./cmd/server"],
        cwd=SERVER_DIR,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
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

    try:
        yield base, proc, ready
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def _req(method: str, url: str, data: bytes | None = None):
    req = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        resp = urllib.request.urlopen(req)
        return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


class TestServerHealth:
    def test_starts_and_healthy(self, server):
        base, proc, ready = server
        assert ready, "server not ready within 15s"
        assert proc.poll() is None, "server process exited"

    def test_healthz(self, server):
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")
        status, body = _req("GET", f"{base}/healthz")
        assert status == 200
        assert body == b'{"status":"ok"}'


class TestProgramCRUD:
    def test_list_empty(self, server):
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")
        status, body = _req("GET", f"{base}/programs")
        assert status == 200
        data = json.loads(body)
        assert isinstance(data, list)

    def test_create(self, server):
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")
        status, body = _req("POST", f"{base}/programs", '{"name":"prog-A"}'.encode())
        assert status == 201
        prog = json.loads(body)
        assert prog["name"] == "prog-A"
        assert "id" in prog

    def test_get_created(self, server):
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")

        _, body = _req("POST", f"{base}/programs", '{"name":"prog-B"}'.encode())
        pid = json.loads(body)["id"]

        status, body = _req("GET", f"{base}/programs/{pid}")
        assert status == 200
        assert json.loads(body)["name"] == "prog-B"

    def test_update(self, server):
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")

        _, body = _req("POST", f"{base}/programs", '{"name":"old"}'.encode())
        pid = json.loads(body)["id"]

        status, body = _req(
            "PUT", f"{base}/programs/{pid}",
            '{"name":"new","status":"published"}'.encode(),
        )
        assert status == 200
        assert json.loads(body)["name"] == "new"

    def test_delete(self, server):
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")

        _, body = _req("POST", f"{base}/programs", '{"name":"to-delete"}'.encode())
        pid = json.loads(body)["id"]

        status, body = _req("DELETE", f"{base}/programs/{pid}")
        assert status == 204

        status, _ = _req("GET", f"{base}/programs/{pid}")
        assert status == 404


class TestCoursePhaseLessonChain:
    def test_full_chain(self, server):
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")

        # 1. Create Course
        _, body = _req("POST", f"{base}/courses", '{"name":"course-A"}'.encode())
        course = json.loads(body)
        cid = course["id"]

        # 2. Create Phase linked to course
        _, body = _req(
            "POST", f"{base}/phases",
            ('{"name":"phase-1","courseId":"' + cid + '","sortOrder":1}').encode(),
        )
        phase = json.loads(body)
        pid = phase["id"]

        # 3. List phases by courseId
        status, body = _req("GET", f"{base}/phases?courseId={cid}")
        assert status == 200
        assert len(json.loads(body)) == 1

        # 4. Create Lesson and link via Phase.lessonIds
        _, body = _req("POST", f"{base}/lessons", '{"title":"lesson-1","duration":45}'.encode())
        lid = json.loads(body)["id"]

        _, body = _req(
            "PUT", f"{base}/phases/{pid}",
            ('{"name":"phase-1","sortOrder":1,"lessonIds":["' + lid + '"]}').encode(),
        )
        assert lid in json.loads(body)["lessonIds"]

        # 5. Delete Phase, verify lesson still exists independently
        _req("DELETE", f"{base}/phases/{pid}")
        status, _ = _req("GET", f"{base}/phases/{pid}")
        assert status == 404

        status, _ = _req("GET", f"{base}/lessons/{lid}")
        assert status == 200


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
        base, _, ready = server
        if not ready:
            pytest.skip("server not ready")

        body = '{"name":"x"}'.encode() if method == "PUT" else None
        status, _ = _req(method, f"{base}{url}", body)
        assert status == 404, f"{method} {url} expected 404, got {status}"
