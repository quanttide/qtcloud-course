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
/// 每个场景是一个操作步骤。异常分支通过嵌套的 `exception` 字段表达。
/// 场景序列按操作流程排序。
/// 如需更细粒度，可通过 `steps` 字段拆分子步骤。
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Scene {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub exception: Option<ExceptionScene>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub steps: Option<Vec<Step>>,
}

/// 异常场景（嵌套在父场景中）
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ExceptionScene {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
}

/// 场景蓝图（单个 Scene 的 Step 级详细设计）
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SceneBlueprint {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
    pub steps: Vec<Step>,
}

/// 步骤（场景内的子步骤，按顺序执行，不分支）
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Step {
    pub title: String,
    pub description: String,
    pub duration_minutes: Option<u32>,
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
            if !exception.is_object() {
                errors.push(format!("scenes[{}] 'exception' 必须为对象（含 title/description/duration_minutes）", i));
            } else {
                if !exception.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
                    errors.push(format!("scenes[{}].exception 缺少非空 'title' 字段", i));
                }
            }
        }
    }

    ValidationResult {
        valid: errors.is_empty(),
        errors,
    }
}

/// 校验场景蓝图 JSON 数据结构完整性（Scene + Steps）
pub fn validate_scene_json(json: &serde_json::Value) -> ValidationResult {
    let mut errors = Vec::new();

    if !json.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("缺少非空 'title' 字段".to_string());
    }
    if !json.get("description").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
        errors.push("缺少非空 'description' 字段".to_string());
    }

    let steps = match json.get("steps") {
        Some(v) if v.is_array() => v.as_array().unwrap(),
        _ => {
            errors.push("缺少 'steps' 数组".to_string());
            return ValidationResult { valid: false, errors };
        }
    };

    for (i, step) in steps.iter().enumerate() {
        if !step.get("title").and_then(|v| v.as_str()).is_some_and(|s| !s.is_empty()) {
            errors.push(format!("steps[{}] 缺少非空 'title' 字段", i));
        }
    }

    ValidationResult {
        valid: errors.is_empty(),
        errors,
    }
}
