"""conftest.py — 加载 fixtures 供所有测试共享。"""
import json
from pathlib import Path

import pytest

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
