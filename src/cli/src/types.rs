use serde::{Deserialize, Serialize};

/// 课程蓝图（Program → Course → Phase → Lesson，不含 Scene）
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CourseBlueprint {
    pub title: String,
    pub description: String,
    pub courses: Vec<Course>,
}

/// 课程（顶层下的一个子课程）
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Course {
    pub title: String,
    pub description: String,
    pub phases: Vec<Phase>,
}

/// 阶段
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Phase {
    pub title: String,
    pub description: String,
    pub lessons: Vec<Lesson>,
}

/// 课时（课程蓝图层级只含标题/描述/时长，不含 Scene）
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Lesson {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
}

/// 课时蓝图（单个 Lesson 的 Scene 级详细设计）
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LessonBlueprint {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
    pub scenes: Vec<Scene>,
}

/// 场景
///
/// 每个场景是一个操作步骤。`exception: true` 标记异常/失败分支，
/// 默认为正常步骤（不输出 exception 字段）。
/// 场景序列按操作流程排序，正常步骤在前，异常分支紧随其后。
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Scene {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
    #[serde(default, skip_serializing_if = "is_false")]
    pub exception: bool,
}

fn is_false(b: &bool) -> bool {
    !b
}

/// Schema 校验结果
#[derive(Debug)]
pub struct ValidationResult {
    pub valid: bool,
    pub errors: Vec<String>,
}

/// 校验课程蓝图 JSON 数据结构完整性（Program → Course → Phase → Lesson）
pub fn validate_course_json(json: &serde_json::Value) -> ValidationResult {
    let mut errors = Vec::new();

    if !json.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("顶层缺少非空 'title' 字段".to_string());
    }
    if !json.get("description").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("顶层缺少非空 'description' 字段".to_string());
    }

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

/// 校验课时蓝图 JSON 数据结构完整性（Lesson + Scenes）
pub fn validate_lesson_json(json: &serde_json::Value) -> ValidationResult {
    let mut errors = Vec::new();

    if !json.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("缺少非空 'title' 字段".to_string());
    }
    if !json.get("description").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("缺少非空 'description' 字段".to_string());
    }

    let scenes = match json.get("scenes") {
        Some(v) if v.is_array() => v.as_array().unwrap(),
        _ => {
            errors.push("缺少 'scenes' 数组".to_string());
            return ValidationResult { valid: false, errors };
        }
    };

    for (i, scene) in scenes.iter().enumerate() {
        if !scene.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
            errors.push(format!("scenes[{}] 缺少非空 'title' 字段", i));
        }
        if let Some(exception) = scene.get("exception") {
            if !exception.is_boolean() {
                errors.push(format!("scenes[{}] 'exception' 必须为布尔值", i));
            }
        }
    }

    ValidationResult {
        valid: errors.is_empty(),
        errors,
    }
}
