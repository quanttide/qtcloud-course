use serde::{Deserialize, Serialize};

/// 课程数据层级：Program → Course → Phase → Lesson → Scene

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Program {
    pub title: String,
    pub description: String,
    pub courses: Vec<Course>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Course {
    pub id: Option<String>,
    pub title: String,
    pub description: String,
    pub phases: Vec<Phase>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Phase {
    pub title: String,
    pub description: String,
    pub lessons: Vec<Lesson>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Lesson {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
    pub scenes: Vec<Scene>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Scene {
    pub title: String,
    #[serde(rename = "type")]
    pub scene_type: SceneType,
    pub description: String,
    pub duration_minutes: Option<u32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum SceneType {
    Lecture,
    Demo,
    Exercise,
    Discussion,
    Quiz,
    Review,
}

/// Schema 校验结果
#[derive(Debug)]
pub struct ValidationResult {
    pub valid: bool,
    pub errors: Vec<String>,
}

/// 校验课程 JSON 数据结构完整性
pub fn validate_course_json(json: &serde_json::Value) -> ValidationResult {
    let mut errors = Vec::new();

    // 检查顶层必需字段
    if !json.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("顶层缺少非空 'title' 字段".to_string());
    }
    if !json.get("description").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("顶层缺少非空 'description' 字段".to_string());
    }

    // 检查 courses 数组
    let courses = match json.get("courses") {
        Some(v) if v.is_array() => v.as_array().unwrap(),
        _ => {
            errors.push("缺少 'courses' 数组".to_string());
            return ValidationResult { valid: false, errors };
        }
    };

    for (i, course) in courses.iter().enumerate() {
        if !course.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
            errors.push(format!("courses[{}] 缺少非空 'title' 字段", i));
        }
        if !course.get("description").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
            errors.push(format!("courses[{}] 缺少非空 'description' 字段", i));
        }

        let phases = match course.get("phases") {
            Some(v) if v.is_array() => v.as_array().unwrap(),
            _ => {
                errors.push(format!("courses[{}] 缺少 'phases' 数组", i));
                continue;
            }
        };

        for (j, phase) in phases.iter().enumerate() {
            if !phase.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
                errors.push(format!("courses[{}].phases[{}] 缺少非空 'title' 字段", i, j));
            }
            if !phase.get("description").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
                errors.push(format!("courses[{}].phases[{}] 缺少非空 'description' 字段", i, j));
            }

            let lessons = match phase.get("lessons") {
                Some(v) if v.is_array() => v.as_array().unwrap(),
                _ => {
                    errors.push(format!("courses[{}].phases[{}] 缺少 'lessons' 数组", i, j));
                    continue;
                }
            };

            for (k, lesson) in lessons.iter().enumerate() {
                if !lesson.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
                    errors.push(format!("courses[{}].phases[{}].lessons[{}] 缺少非空 'title' 字段", i, j, k));
                }
                if !lesson.get("description").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
                    errors.push(format!("courses[{}].phases[{}].lessons[{}] 缺少非空 'description' 字段", i, j, k));
                }
            }
        }
    }

    ValidationResult {
        valid: errors.is_empty(),
        errors,
    }
}
