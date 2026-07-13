"""Fixture 数据模型校验。"""

import json
from pathlib import Path


class TestFixturesExist:
    """所有 fixture 文件存在且为合法 JSON。"""

    def test_all_files_exist_and_valid(self, fixtures_dir: Path):
        expected = ["programs", "courses", "phases", "lessons", "scenes", "classes"]
        for name in expected:
            path = fixtures_dir / f"{name}.json"
            assert path.exists(), f"Missing fixture: {path.name}"
            data = json.loads(path.read_text())
            assert isinstance(data, list), f"{path.name}: expected a list"
            assert len(data) > 0, f"{path.name}: empty list"


class TestPrograms:
    def test_fields(self, programs):
        for p in programs:
            assert "id" in p
            assert "name" in p
            assert "courseIds" in p
            assert isinstance(p["courseIds"], list)

    def test_ids_unique(self, programs):
        ids = [p["id"] for p in programs]
        assert len(ids) == len(set(ids))


class TestCourses:
    def test_fields(self, courses):
        for c in courses:
            assert "id" in c
            assert "name" in c
            assert "status" in c
            assert c["status"] in ("draft", "published")

    def test_ids_unique(self, courses):
        ids = [c["id"] for c in courses]
        assert len(ids) == len(set(ids))


class TestPhases:
    def test_fields(self, phases):
        for p in phases:
            assert "id" in p
            assert "courseId" in p
            assert "name" in p
            assert "lessonIds" in p
            assert isinstance(p["lessonIds"], list)

    def test_links_to_existing_courses(self, phases, courses):
        course_ids = {c["id"] for c in courses}
        for p in phases:
            assert p["courseId"] in course_ids, (
                f"Phase {p['id']} references unknown course {p['courseId']}"
            )


class TestLessons:
    def test_fields(self, lessons):
        for l in lessons:
            assert "id" in l
            assert "title" in l
            assert "duration" in l
            assert l["duration"] > 0

    def test_ids_unique(self, lessons):
        ids = [l["id"] for l in lessons]
        assert len(ids) == len(set(ids))


class TestScenes:
    def test_fields(self, scenes):
        for s in scenes:
            assert "id" in s
            assert "lessonId" in s
            assert "videoUrl" in s
            assert "choices" in s
            assert isinstance(s["choices"], list)

    def test_links_to_existing_lessons(self, scenes, lessons):
        lesson_ids = {l["id"] for l in lessons}
        for s in scenes:
            assert s["lessonId"] in lesson_ids, (
                f"Scene {s['id']} references unknown lesson {s['lessonId']}"
            )

    def test_targets_exist(self, scenes):
        scene_ids = {s["id"] for s in scenes}
        for s in scenes:
            for choice in s["choices"]:
                target = choice["targetSceneId"]
                assert target in scene_ids, (
                    f"Scene {s['id']} choice '{choice['label']}' "
                    f"targets unknown scene {target}"
                )


class TestClasses:
    def test_fields(self, classes):
        for c in classes:
            assert "id" in c
            assert "name" in c
            assert "refId" in c
            assert "startDate" in c
            assert "endDate" in c

    def test_ref_types(self, classes):
        for c in classes:
            assert c.get("refType") in ("program", "course")
