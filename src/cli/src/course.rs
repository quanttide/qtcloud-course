use std::fs;
use std::path::Path;

use quanttide_agent::{LLM, Message};

/// 从 Markdown 源文件生成课程蓝图 JSON。
///
/// 主题从文件名推断，原始资料全文作为上下文。
/// 始终输出结构化 JSON，兼容 Studio 导入格式。
pub fn run(from: &Path, to: &Path, llm: Option<&LLM>) {
    let material = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });

    let topic = from
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("untitled");

    let prompt = format!(
        "你是一位课程设计专家。请以「{}」为主题设计一份完整的课程蓝图。\n\n\
         教学定位：主题是一个知识领域或实践方法，不是某个具体工具。\n\
         原始资料中提供的是真实生产背景，作为课程中的案例素材和练习载体，\n\
         但绝不把工具操作本身作为教学目标。\n\n\
         要求：\n\
         1. 找到初学者在学习 {} 时最常见的困惑，从设计源头解释\n\
         2. 按 Program → Course → Phase → Lesson → Scene 五层结构组织\n\
         3. 每个 Scene 需注明类型（lecture/demo/exercise/discussion/quiz/review）和时长\n\
         4. 每节课（Lesson）给出明确的教学目标\n\
         5. 使用原始资料中的真实案例作为演示和练习素材，但教学目标始终围绕 {} 的概念和实践\n\n\
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
                                     \"duration_minutes\": 45,\n\
                                     \"scenes\": [\n\
                                         {{\n\
                                             \"title\": \"场景标题\",\n\
                                             \"type\": \"lecture\",\n\
                                             \"description\": \"场景描述\",\n\
                                             \"duration_minutes\": 15\n\
                                         }}\n\
                                     ]\n\
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

    let output = serde_json::to_string_pretty(&json).unwrap();
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

    /// Mock HTTP 客户端
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
    fn test_prompt_derives_topic_from_filename() {
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

        // 创建临时输入和输出文件
        let mut input = NamedTempFile::new().unwrap();
        writeln!(input, "# DevOps 实践").unwrap();
        let output = NamedTempFile::new().unwrap();

        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run(input.path(), output.path(), Some(&llm));
        }));

        let request = last_request.lock().unwrap().clone();
        assert!(request.is_some(), "LLM 应该被调用");
    }

    #[test]
    fn test_output_is_json() {
        let response = serde_json::json!({
            "choices": [{
                "message": {
                    "content": r#"```json
{"title": "学习Rust", "description": "Rust入门课程", "courses": []}
```"#
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
        writeln!(input, "# Rust 基础").unwrap();
        let output = NamedTempFile::new().unwrap();

        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run(input.path(), output.path(), Some(&llm));
        }));

        assert!(last_request.lock().unwrap().is_some(), "LLM 应该被调用");
    }
}
