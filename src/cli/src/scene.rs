use std::fs;
use std::path::Path;

use quanttide_agent::{LLM, Message};

/// 从 Markdown 源文件生成场景蓝图 JSON（Scene → Steps）。
///
/// 场景内的步骤按顺序执行，不分支。
pub fn run_blueprint(from: &Path, to: &Path, llm: Option<&LLM>) {
    let material = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });

    let topic = from
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("untitled");

    let prompt = format!(
        "你是一位课程设计专家。请为场景「{}」设计详细的步骤蓝图。\n\n\
         要求：\n\
         1. 拆解为 3-6 个按顺序执行的子步骤\n\
         2. 每个步骤有具体的操作描述和时长\n\
         3. 步骤之间不分支，按操作流程依次执行\n\
         4. 使用原始资料中的真实案例丰富步骤描述\n\n\
         请严格按照以下 JSON 格式输出，不要包含其他内容：\n\
         {{\n\
             \"title\": \"场景标题\",\n\
             \"description\": \"场景描述\",\n\
             \"duration_minutes\": 15,\n\
             \"steps\": [\n\
                 {{\n\
                     \"title\": \"步骤名称\",\n\
                     \"description\": \"具体操作描述\",\n\
                     \"duration_minutes\": 5\n\
                 }}\n\
             ]\n\
         }}",
        topic
    );

    let full_prompt = format!("{}\n\n## 原始资料\n\n{}", prompt, material);

    send_and_write(&full_prompt, to, llm);
}

/// 基于已有场景蓝图 + 人类指示迭代修改。
pub fn run_design(file: &Path, instruction: &str, to: &Path, llm: Option<&LLM>) {
    let existing = fs::read_to_string(file).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", file.display(), e);
        std::process::exit(1);
    });

    let _existing_json: serde_json::Value = serde_json::from_str(&existing).unwrap_or_else(|e| {
        eprintln!("错误：{} 不是合法的 JSON - {}", file.display(), e);
        std::process::exit(1);
    });

    let prompt = format!(
        "你是一位课程设计专家。请根据用户的设计指示，修改已有的场景蓝图。\n\n\
         设计要求：{}\n\n\
         注意事项：\n\
         1. 保持步骤的顺序结构（steps 数组）\n\
         2. 只修改用户要求的部分，其他部分保持不变\n\
         3. 输出完整的场景蓝图 JSON，不要省略任何字段\n\n\
         请严格按照以下 JSON 格式输出，不要包含其他内容：\n\
         {{\n\
             \"title\": \"场景标题\",\n\
             \"description\": \"场景描述\",\n\
             \"duration_minutes\": 15,\n\
             \"steps\": [\n\
                 {{\n\
                     \"title\": \"步骤名称\",\n\
                     \"description\": \"具体操作描述\",\n\
                     \"duration_minutes\": 5\n\
                 }}\n\
             ]\n\
         }}",
        instruction
    );

    let full_prompt = format!("{}\n\n## 当前场景蓝图\n\n{}", prompt, existing);

    send_and_write(&full_prompt, to, llm);
}

fn send_and_write(full_prompt: &str, to: &Path, llm: Option<&LLM>) {
    let default_llm;
    let llm_ref: &LLM = match llm {
        Some(l) => l,
        None => {
            default_llm = LLM::default();
            &default_llm
        }
    };

    let messages = vec![Message::new("user", full_prompt)];
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

    let validation = crate::types::validate_scene_json(&json);
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
    fn test_blueprint_output_has_steps() {
        let response = serde_json::json!({
            "choices": [{
                "message": {
                    "content": r#"{"title": "检查版本号", "description": "确认版本一致性", "duration_minutes": 10, "steps": [{"title": "检查pyproject.toml", "description": "确认版本字段", "duration_minutes": 3}]}"#
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
        writeln!(input, "# 检查版本号").unwrap();
        let output = NamedTempFile::new().unwrap();

        let _result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            run_blueprint(input.path(), output.path(), Some(&llm));
        }));

        let request = last_request.lock().unwrap().clone();
        assert!(request.is_some(), "LLM 应该被调用");
    }
}
