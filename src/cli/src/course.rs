use std::fs;
use std::path::PathBuf;
use std::process;

use quanttide_agent::{LLM, Message};

/// 生成课程蓝图。
///
/// 支持可选的 LLM 注入（用于测试）。
pub fn run(
    topic: &str,
    input_path: Option<PathBuf>,
    output_path: Option<PathBuf>,
    format_json: bool,
    llm: Option<&LLM>,
) {
    // 构造优化后的提示词，要求按 Program → Course → Phase → Lesson → Scene 层级输出
    let mut prompt = format!(
        "你是一位课程设计专家。请为「{}」设计一份完整的课程蓝图。\n\n\
         要求：\n\
         1. 找到一个初学者在使用 {} 时最具体的操作困惑，回到设计源头解释它\n\
         2. 按 Program → Course → Phase → Lesson → Scene 五层结构组织\n\
         3. 每个 Scene 需注明类型（lecture/demo/exercise/discussion/quiz/review）和时长\n\
         4. 每节课（Lesson）给出教学目标\n\n\
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
        topic, topic
    );

    if let Some(ref path) = input_path {
        let material = fs::read_to_string(path).unwrap_or_else(|e| {
            eprintln!("错误：读取 {} 失败 - {}", path.display(), e);
            process::exit(1);
        });
        prompt.push_str("\n\n## 原始资料\n\n");
        prompt.push_str(&material);
    }

    let default_llm;
    let llm_ref: &LLM = match llm {
        Some(l) => l,
        None => {
            default_llm = LLM::default();
            &default_llm
        }
    };

    let messages = vec![Message::new("user", &prompt)];
    let options = Default::default();

    let resp = llm_ref.complete(&messages, options).unwrap_or_else(|e| {
        eprintln!("错误：{}", e);
        process::exit(1);
    });

    if format_json {
        // 尝试从 LLM 回复中提取 JSON
        let json = quanttide_agent::parse_structured_output(&resp.content)
            .unwrap_or_else(|e| {
                eprintln!("错误：无法从 LLM 回复中解析 JSON - {}", e);
                eprintln!("原始回复：\n{}", resp.content);
                process::exit(1);
            });

        // 可选：对结构化 JSON 做校验
        let validation = crate::types::validate_course_json(&json);
        if !validation.valid {
            eprintln!("警告：生成的 JSON 不完整");
            for err in &validation.errors {
                eprintln!("  - {}", err);
            }
        }

        let output = serde_json::to_string_pretty(&json).unwrap();
        match output_path {
            Some(path) => {
                fs::write(&path, &output).unwrap_or_else(|e| {
                    eprintln!("错误：写入 {} 失败 - {}", path.display(), e);
                    process::exit(1);
                });
                eprintln!("已写入：{}", path.display());
            }
            None => println!("{}", output),
        }
    } else {
        match output_path {
            Some(path) => {
                fs::write(&path, &resp.content).unwrap_or_else(|e| {
                    eprintln!("错误：写入 {} 失败 - {}", path.display(), e);
                    process::exit(1);
                });
                eprintln!("已写入：{}", path.display());
            }
            None => println!("{}", resp.content),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use quanttide_agent::{HttpClient, LLM, LLMError};
    use serde_json::Value;
    use std::sync::{Arc, Mutex};

    /// Mock HTTP 客户端，记录最后一次请求 payload 并返回预设响应
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
    fn test_prompt_contains_topic() {
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

        // 捕获 stdout 避免测试输出混乱
        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run("Rust", None, None, false, Some(&llm));
        }));

        let request = last_request.lock().unwrap().clone();
        assert!(request.is_some(), "LLM 应该被调用");

        if let Some(body) = request {
            let messages = body["messages"].as_array().unwrap();
            let user_msg = messages[0]["content"].as_str().unwrap();
            assert!(user_msg.contains("Rust"), "提示词应包含主题");
            assert!(user_msg.contains("Lesson"), "提示词应包含 Lesson 层级");
            assert!(user_msg.contains("Scene"), "提示词应包含 Scene 层级");
        }
    }

    #[test]
    fn test_format_json_output() {
        let response = serde_json::json!({
            "choices": [{
                "message": {
                    "content": r#"```json
{"title": "学习Rust", "description": "Rust入门课程", "courses": [{"title": "基础", "description": "基础部分", "phases": [{"title": "入门", "description": "入门阶段", "lessons": [{"title": "第一课", "description": "学会基础", "duration_minutes": 45, "scenes": [{"title": "介绍", "type": "lecture", "description": "课程介绍", "duration_minutes": 15}]}]}]}]}
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

        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run("Rust", None, None, true, Some(&llm));
        }));

        assert!(last_request.lock().unwrap().is_some(), "LLM 应该被调用");
    }
}
