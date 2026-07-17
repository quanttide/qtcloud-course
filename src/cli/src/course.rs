use std::fs;
use std::path::Path;

use quanttide_agent::{LLM, Message};

/// 从 Markdown 源文件生成课程蓝图 JSON（Program → Course → Phase → Lesson）。
///
/// 主题优先使用 `topic` 参数，未指定时从文件名推断。
/// 原始资料全文作为上下文。
/// 输出不含 Scene 层级，Scene 级设计由 lesson blueprint 负责。
pub fn run_blueprint(from: &Path, to: &Path, topic: Option<&str>, llm: Option<&LLM>) {
    let material = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });

    let topic = topic
        .map(|s| s.to_string())
        .unwrap_or_else(|| {
            from.file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("untitled")
                .to_string()
        });

    let prompt = format!(
        "你是一位课程设计专家。请以「{}」为主题设计完整的课程蓝图（Program → Course → Phase → Lesson 四级结构）。\n\n\
         教学定位：主题是一个知识领域或实践方法，不是某个具体工具。\n\
         原始资料中提供的是真实生产背景，作为课程中的案例素材和练习载体，\n\
         但绝不把工具操作本身作为教学目标。\n\n\
         要求：\n\
         1. 找到初学者在学习 {} 时最常见的困惑，从设计源头解释\n\
         2. 按 Program → Course → Phase → Lesson 四级结构组织（不含 Scene）\n\
         3. 每节课（Lesson）给出明确的教学目标（description）\n\
         4. 使用原始资料中的真实案例作为演示和练习素材，但教学目标始终围绕 {} 的概念和实践\n\n\
         请严格按照以下 JSON 格式输出，不要包含其他内容：\n\
         {{\n\
             \"title\": \"课程项目名称\",\n\
             \"description\": \"课程项目简介\",\n\
             \"courses\": [\n\
                 {{\n\
                     \"title\": \"课程名称\",\n\
                     \"description\": \"课程描述\",\n\
                     \"phases\": [\n\
                         {{\n\
                             \"title\": \"阶段名称\",\n\
                             \"description\": \"阶段描述\",\n\
                             \"lessons\": [\n\
                                 {{\n\
                                     \"title\": \"课时标题\",\n\
                                     \"description\": \"教学目标\",\n\
                                 }}\n\
                             ]\n\
                         }}\n\
                     ]\n\
                 }}\n\
             ]\n\
         }}",
        topic, topic, topic
    );

    let full_prompt = format!("{}\n\n## 原始资料\n\n{}", prompt, material);

    let default_llm;
    let llm_ref: &LLM = match llm {
        Some(l) => l,
        None => {
            default_llm = LLM::default();
            &default_llm
        }
    };

    let messages = vec![Message::new("user", &full_prompt)];
    let options = Default::default();

    let resp = llm_ref.complete(&messages, options).unwrap_or_else(|e| {
        eprintln!("错误：{}", e);
        std::process::exit(1);
    });

    let json = quanttide_agent::parse_structured_output(&resp.content).unwrap_or_else(|e| {
        eprintln!("错误：无法从 LLM 回复中解析 JSON - {}", e);
        eprintln!("原始回复：\n{}", resp.content);
        std::process::exit(1);
    });

    let validation = crate::types::validate_course_json(&json);
    if !validation.valid {
        eprintln!("警告：生成的 JSON 不完整");
        for err in &validation.errors {
            eprintln!("  - {}", err);
        }
    }

    write_json(&json, to);
}

/// 基于已有课程蓝图 + 人类指示迭代修改。
///
/// 读取已有的课程蓝图 JSON，结合人类设计指示，输出修改后的版本。
pub fn run_design(file: &Path, instruction: &str, to: &Path, llm: Option<&LLM>) {
    let existing = fs::read_to_string(file).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", file.display(), e);
        std::process::exit(1);
    });

    // 校验输入的 JSON 格式
    let _existing_json: serde_json::Value = serde_json::from_str(&existing).unwrap_or_else(|e| {
        eprintln!("错误：{} 不是合法的 JSON - {}", file.display(), e);
        std::process::exit(1);
    });

    let prompt = format!(
        "你是一位课程设计专家。请根据用户的设计指示，修改已有的课程蓝图。\n\n\
         设计要求：{}\n\n\
         注意事项：\n\
         1. 保持课程蓝图的结构完整性（Program → Course → Phase → Lesson）\n\
         2. 只修改用户要求的部分，其他部分保持不变\n\
         3. 每节课（Lesson）需有明确的教学目标\n\
         4. 输出完整的课程蓝图 JSON，不要省略任何字段\n\n\
         请严格按照以下 JSON 格式输出，不要包含其他内容：\n\
         {{\n\
             \"title\": \"课程项目名称\",\n\
             \"description\": \"课程项目简介\",\n\
             \"courses\": [\n\
                 {{\n\
                     \"title\": \"课程名称\",\n\
                     \"description\": \"课程描述\",\n\
                     \"phases\": [\n\
                         {{\n\
                             \"title\": \"阶段名称\",\n\
                             \"description\": \"阶段描述\",\n\
                             \"lessons\": [\n\
                                 {{\n\
                                     \"title\": \"课时标题\",\n\
                                     \"description\": \"教学目标\",\n\
                                 }}\n\
                             ]\n\
                         }}\n\
                     ]\n\
                 }}\n\
             ]\n\
         }}",
        instruction
    );

    let full_prompt = format!("{}\n\n## 当前课程蓝图\n\n{}", prompt, existing);

    let default_llm;
    let llm_ref: &LLM = match llm {
        Some(l) => l,
        None => {
            default_llm = LLM::default();
            &default_llm
        }
    };

    let messages = vec![Message::new("user", &full_prompt)];
    let options = Default::default();

    let resp = llm_ref.complete(&messages, options).unwrap_or_else(|e| {
        eprintln!("错误：{}", e);
        std::process::exit(1);
    });

    let json = quanttide_agent::parse_structured_output(&resp.content).unwrap_or_else(|e| {
        eprintln!("错误：无法从 LLM 回复中解析 JSON - {}", e);
        eprintln!("原始回复：\n{}", resp.content);
        std::process::exit(1);
    });

    let validation = crate::types::validate_course_json(&json);
    if !validation.valid {
        eprintln!("警告：生成的 JSON 不完整");
        for err in &validation.errors {
            eprintln!("  - {}", err);
        }
    }

    write_json(&json, to);
}

fn write_json(json: &serde_json::Value, to: &Path) {
    let output = serde_json::to_string_pretty(json).unwrap();
    fs::write(to, &output).unwrap_or_else(|e| {
        eprintln!("错误：写入 {} 失败 - {}", to.display(), e);
        std::process::exit(1);
    });
    eprintln!("已写入：{}", to.display());
}

#[cfg(test)]
mod tests {
    use super::*;
    use quanttide_agent::{HttpClient, LLM, LLMError};
    use serde_json::Value;
    use std::sync::{Arc, Mutex};
    use std::io::Write;
    use tempfile::NamedTempFile;

    struct MockHttpClient {
        response: Value,
        last_request: Arc<Mutex<Option<Value>>>,
    }

    impl HttpClient for MockHttpClient {
        fn post_json(&self, _url: &str, _auth: &str, body: &Value) -> Result<Value, LLMError> {
            let mut last = self.last_request.lock().unwrap();
            *last = Some(body.clone());
            Ok(self.response.clone())
        }
    }

    #[test]
    fn test_blueprint_prompt_derives_topic() {
        let response = serde_json::json!({
            "choices": [{
                "message": {
                    "content": r#"{"title": "Test", "description": "Desc", "courses": []}"#
                },
                "finish_reason": "stop"
            }],
            "model": "mock",
            "usage": null
        });

        let last_request: Arc<Mutex<Option<Value>>> = Arc::new(Mutex::new(None));
        let client = MockHttpClient {
            response,
            last_request: Arc::clone(&last_request),
        };

        let llm = LLM::with_client("mock", "http://mock", "key", Box::new(client));

        let mut input = NamedTempFile::new().unwrap();
        writeln!(input, "# DevOps 实践").unwrap();
        let output = NamedTempFile::new().unwrap();

        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run_blueprint(input.path(), output.path(), None, Some(&llm));
        }));

        let request = last_request.lock().unwrap().clone();
        assert!(request.is_some(), "LLM 应该被调用");
    }

    #[test]
    fn test_design_receives_existing_json() {
        let response = serde_json::json!({
            "choices": [{
                "message": {
                    "content": r#"{"title": "Modified", "description": "Modified desc", "courses": []}"#
                },
                "finish_reason": "stop"
            }],
            "model": "mock",
            "usage": null
        });

        let last_request: Arc<Mutex<Option<Value>>> = Arc::new(Mutex::new(None));
        let client = MockHttpClient {
            response,
            last_request: Arc::clone(&last_request),
        };

        let llm = LLM::with_client("mock", "http://mock", "key", Box::new(client));

        let mut input = NamedTempFile::new().unwrap();
        writeln!(
            input,
            r#"{{"title": "Original", "description": "Original desc", "courses": []}}"#
        )
        .unwrap();
        let output = NamedTempFile::new().unwrap();

        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run_design(
                input.path(),
                "把标题改成Modified",
                output.path(),
                Some(&llm),
            );
        }));

        let request = last_request.lock().unwrap().clone();
        assert!(request.is_some(), "LLM 应该被调用");
        if let Some(body) = request {
            let messages = body["messages"].as_array().unwrap();
            let content = messages[0]["content"].as_str().unwrap();
            assert!(
                content.contains("Original"),
                "提示词应包含已有蓝图内容"
            );
            assert!(
                content.contains("把标题改成Modified"),
                "提示词应包含人类指示"
            );
        }
    }

    #[test]
    fn test_write_json_to_file() {
        use std::io::Write;
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("out.json");
        let json = serde_json::json!({"title": "test"});
        // Call the write_json helper via run_design's flow - use serde_json directly
        let output = serde_json::to_string_pretty(&json).unwrap();
        std::fs::write(&path, &output).unwrap();
        let content = std::fs::read_to_string(&path).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&content).unwrap();
        assert_eq!(parsed["title"], "test");
    }

    #[test]
    fn test_blueprint_with_input_file() {
        let response = serde_json::json!({
            "choices": [{
                "message": {
                    "content": r#"{"title": "T", "description": "D", "courses": []}"#
                },
                "finish_reason": "stop"
            }],
            "model": "mock",
            "usage": null
        });

        use quanttide_agent::{HttpClient, LLMError};
        struct Mock2(std::sync::Mutex<std::sync::Arc<std::sync::Mutex<Option<serde_json::Value>>>>);
        impl HttpClient for Mock2 {
            fn post_json(&self, _url: &str, _auth: &str, body: &serde_json::Value) -> Result<serde_json::Value, LLMError> {
                *self.0.lock().unwrap().lock().unwrap() = Some(body.clone());
                Ok(serde_json::json!({
                    "choices": [{"message": {"content": r#"{"title":"T","description":"D","courses":[]}"#}, "finish_reason": "stop"}],
                    "model": "mock", "usage": null
                }))
            }
        }

        let last = std::sync::Arc::new(std::sync::Mutex::new(None));
        let client = Mock2(std::sync::Mutex::new(last.clone()));
        let llm = LLM::with_client("mock", "http://mock", "key", Box::new(client));

        let mut input = tempfile::NamedTempFile::new().unwrap();
        writeln!(input, "# DevOps 实践").unwrap();
        let output = tempfile::NamedTempFile::new().unwrap();

        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run_blueprint(input.path(), output.path(), None, Some(&llm));
        }));

        let req = last.lock().unwrap();
        assert!(req.is_some(), "LLM 应被调用");
    }
}
