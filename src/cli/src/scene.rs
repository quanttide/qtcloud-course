use std::fs;
use std::path::Path;

use quanttide_agent::{LLM, Message};

/// 从 Markdown 源文件生成场景蓝图 JSON（Scene → Steps）。
///
/// 场景内的步骤按顺序执行，不分支。
/// 主题优先使用 `topic` 参数，未指定时从内容第一个 H1 标题推断。
pub fn run_blueprint(from: &Path, to: &Path, topic: Option<&str>, llm: Option<&LLM>) {
    let material = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });

    let topic = topic
        .map(|s| s.to_string())
        .unwrap_or_else(|| {
            material
                .lines()
                .find(|line| line.starts_with("# "))
                .map(|line| line.trim_start_matches("# ").trim().to_string())
                .unwrap_or_else(|| "untitled".to_string())
        });

    let prompt = format!(
        "你是一位课程设计专家。请为场景「{}」设计详细的步骤蓝图。\n\n\
         要求：\n\
         1. 拆解为 3-6 个按顺序执行的子步骤\n\
         2. 每个步骤有具体的操作描述\n\
         3. 步骤之间不分支，按操作流程依次执行\n\
         4. 使用原始资料中的真实案例丰富步骤描述\n\n\
         请严格按照以下 JSON 格式输出，不要包含其他内容：\n\
         {{\n\
             \"title\": \"场景标题\",\n\
             \"description\": \"场景描述\",\n\
             \"steps\": [\n\
                 {{\n\
                     \"title\": \"步骤名称\",\n\
                     \"description\": \"具体操作描述\"\n\
                 }}\n\
             ]\n\
         }}",
        topic
    );

    let full_prompt = format!("{}\n\n## 原始资料\n\n{}", prompt, material);
    send_and_write(&full_prompt, to, llm);
}

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
             \"steps\": [\n\
                 {{\n\
                     \"title\": \"步骤名称\",\n\
                     \"description\": \"具体操作描述\"\n\
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
        None => { default_llm = LLM::default(); &default_llm }
    };
    let messages = vec![Message::new("user", full_prompt)];
    let resp = llm_ref.complete(&messages, Default::default()).unwrap_or_else(|e| {
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
