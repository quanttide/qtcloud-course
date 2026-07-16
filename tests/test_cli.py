"""CLI 集成测试 — 编译 qtcloud-course 二进制，对 Provider 运行子命令。

测试策略：cargo build → 启动 Provider → 运行 CLI 子命令 → 断言 stdout/stderr/exit code。

与 test_provider.py 各自独立构建二进制，不共享 fixture。"""

import json
import os
import socket
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CLI_DIR = PROJECT_ROOT / "src" / "cli"
BINARY_PATH = CLI_DIR / "target" / "debug" / "qtcloud-course"
SERVER_DIR = PROJECT_ROOT / "src" / "provider"
BINARY_DIR = SERVER_DIR / "bin"
SERVER_BINARY = BINARY_DIR / "server"
FIXTURES_DIR = PROJECT_ROOT / "tests" / "fixtures"


# ── 帮助函数 ──────────────────────────────────────────────────────────


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def _build_go_server() -> Path:
    """编译 Provider Go 二进制。"""
    BINARY_DIR.mkdir(exist_ok=True)
    subprocess.run(
        ["go", "build", "-o", str(SERVER_BINARY), "./cmd/server"],
        cwd=str(SERVER_DIR),
        check=True,
        capture_output=True,
        text=True,
    )
    return SERVER_BINARY


def _start_server(binary: Path) -> tuple[str, subprocess.Popen]:
    """启动 Provider 实例，返回 (base_url, proc)。"""
    host = "127.0.0.1"
    port = _free_port()
    base = f"http://{host}:{port}"

    env = os.environ.copy()
    env["LISTEN_ADDR"] = f"{host}:{port}"

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


# ── Session-scoped fixtures ──────────────────────────────────────────


@pytest.fixture(scope="session")
def cli_binary():
    """编译 CLI Rust 二进制。"""
    subprocess.run(
        ["cargo", "build"],
        cwd=str(CLI_DIR),
        check=True,
        capture_output=True,
        text=True,
    )
    assert BINARY_PATH.exists(), f"CLI binary not found at {BINARY_PATH}"
    return BINARY_PATH


@pytest.fixture(scope="session")
def server_binary():
    """编译 Provider Go 二进制。"""
    return _build_go_server()


# ── Module-scoped fixtures ──────────────────────────────────────────


@pytest.fixture(scope="module")
def server(server_binary):
    """启动 Provider，返回 (base_url, proc)。"""
    base, proc = _start_server(server_binary)
    try:
        yield base, proc
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


@pytest.fixture
def cli(cli_binary, server):
    """返回 CLI runner 函数，自动指向测试中的 Provider 实例。"""
    base_url, _ = server

    def _run(*args: str, expected_code: int = 0) -> subprocess.CompletedProcess:
        env = os.environ.copy()
        env["QTCLOUD_API_BASE_URL"] = base_url
        env["LLM_API_KEY"] = "sk-test-key"
        result = subprocess.run(
            [str(cli_binary), *args],
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != expected_code:
            print(f"  stdout: {result.stdout}")
            print(f"  stderr: {result.stderr}")
            pytest.fail(
                f"CLI exited with {result.returncode}, expected {expected_code}\n"
                f"args: {args}\n"
                f"stderr: {result.stderr}"
            )
        return result

    return _run


# ── Validate ─────────────────────────────────────────────────────────


class TestValidate:
    """validate 子命令：纯本地 JSON schema 校验，不依赖服务器。"""

    def test_valid_json(self, cli, tmp_path):
        fp = tmp_path / "valid.json"
        fp.write_text(json.dumps({
            "title": "测试课程",
            "description": "描述",
            "courses": [{
                "title": "基础",
                "description": "基础部分",
                "phases": [{
                    "title": "入门",
                    "description": "入门阶段",
                    "lessons": [{
                        "title": "第一课",
                        "description": "学会基础",
                        "duration_minutes": 45,
                        "scenes": [{
                            "title": "介绍",
                            "type": "lecture",
                            "description": "课程介绍",
                            "duration_minutes": 15
                        }]
                    }]
                }]
            }]
        }))
        result = cli("validate", str(fp))
        assert "校验通过" in result.stdout

    def test_missing_title(self, cli, tmp_path):
        fp = tmp_path / "bad.json"
        fp.write_text(json.dumps({"description": "无标题", "courses": []}))
        result = cli("validate", str(fp), expected_code=1)
        assert "校验失败" in result.stderr
        assert "title" in result.stderr

    def test_missing_courses(self, cli, tmp_path):
        fp = tmp_path / "bad.json"
        fp.write_text(json.dumps({"title": "测试"}))
        result = cli("validate", str(fp), expected_code=1)
        assert "校验失败" in result.stderr
        assert "courses" in result.stderr

    def test_invalid_json_syntax(self, cli, tmp_path):
        fp = tmp_path / "invalid.json"
        fp.write_text("not json at all")
        result = cli("validate", str(fp), expected_code=1)
        assert "JSON 解析失败" in result.stderr


# ── Import / Export ─────────────────────────────────────────────────


class TestImportExport:
    """import/export 子命令：CLI ↔ Provider API 双向数据管线。"""

    def test_import_program(self, cli, tmp_path):
        """从 fixture 数据导入，验证返回 201 级响应。"""
        programs = json.loads((FIXTURES_DIR / "programs.json").read_text())
        fp = tmp_path / "prog.json"
        fp.write_text(json.dumps(programs[0]))
        result = cli("import", str(fp))
        data = json.loads(result.stdout)
        assert "id" in data
        assert data["name"] == programs[0]["name"]

    def test_import_then_export(self, cli, tmp_path):
        """导入后导出，验证 round-trip 数据一致性。"""
        programs = json.loads((FIXTURES_DIR / "programs.json").read_text())
        prog = programs[0]

        # 导入
        fp = tmp_path / "prog.json"
        fp.write_text(json.dumps(prog))
        import_result = cli("import", str(fp))
        imported = json.loads(import_result.stdout)
        pid = imported["id"]

        # 导出
        export_path = tmp_path / "exported.json"
        cli("export", pid, "--output-path", str(export_path))

        exported = json.loads(export_path.read_text())
        assert exported["name"] == prog["name"]

    def test_export_nonexistent(self, cli):
        """导出不存在的 program 应报错。"""
        result = cli("export", "nonexistent-id", expected_code=1)
        assert result.returncode == 1

    def test_import_existing(self, cli, tmp_path):
        """连续两次导入同一数据，第二次应当成功（创建新记录，非幂等）。"""
        programs = json.loads((FIXTURES_DIR / "programs.json").read_text())
        fp = tmp_path / "prog.json"
        fp.write_text(json.dumps(programs[0]))

        r1 = cli("import", str(fp))
        id1 = json.loads(r1.stdout)["id"]

        r2 = cli("import", str(fp))
        id2 = json.loads(r2.stdout)["id"]

        assert id1 != id2, "两次导入应返回不同 ID"


# ── Course 子命令烟雾测试 ────────────────────────────────────────────


class TestCourseCommand:
    """course 子命令：验证 CLI 参数解析和帮助输出。

    course 实际 LLM 调用已在 Rust 单元测试中覆盖（#[cfg(test)]），
    这里只验证 CLI 框架层参数解析正确。
    """

    def test_course_help(self, cli):
        """--help 应显示子命令说明。"""
        result = cli("course", "--help")
        assert "生成课程蓝图" in result.stdout
        assert "--format" in result.stdout
        assert "--input-path" in result.stdout
        assert "--output-path" in result.stdout
        assert "topic" in result.stdout
