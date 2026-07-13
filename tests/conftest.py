"""conftest.py — 加载 fixtures 供所有测试共享。"""
import json
from pathlib import Path

import pytest

from tests.utils.gui import check_tool, has_tesseract_cn as _has_tesseract_cn

FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture(scope="session")
def fixtures_dir() -> Path:
    return FIXTURES_DIR


@pytest.fixture(scope="session")
def programs() -> list[dict]:
    return json.loads((FIXTURES_DIR / "programs.json").read_text())


@pytest.fixture(scope="session")
def courses() -> list[dict]:
    return json.loads((FIXTURES_DIR / "courses.json").read_text())


@pytest.fixture(scope="session")
def phases() -> list[dict]:
    return json.loads((FIXTURES_DIR / "phases.json").read_text())


@pytest.fixture(scope="session")
def lessons() -> list[dict]:
    return json.loads((FIXTURES_DIR / "lessons.json").read_text())


@pytest.fixture(scope="session")
def scenes() -> list[dict]:
    return json.loads((FIXTURES_DIR / "scenes.json").read_text())


@pytest.fixture(scope="session")
def classes() -> list[dict]:
    return json.loads((FIXTURES_DIR / "classes.json").read_text())


# ── GUI 工具检测 fixtures ────────────────────────────────────────────


@pytest.fixture(scope="session")
def has_xvfb():
    return check_tool("xvfb-run") is not None or check_tool("Xvfb") is not None


@pytest.fixture(scope="session")
def has_xdotool():
    return check_tool("xdotool") is not None


@pytest.fixture(scope="session")
def has_import():
    return check_tool("import") is not None


@pytest.fixture(scope="session")
def has_tesseract_cn():
    return _has_tesseract_cn()


@pytest.fixture(scope="session")
def has_opencv():
    try:
        import cv2  # noqa: F401
        return True
    except ImportError:
        return False
