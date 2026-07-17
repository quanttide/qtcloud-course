use std::fs;
use std::path::Path;

use quanttide_agent::{LLM, Message};

/// 从 Markdown 源文件生成课时蓝图 JSON（Lesson → Scene）。
///
/// 两遍 LLM 调用：
/// 1. 切场景 — 从素材提取原始操作步骤（无序，无异常）
/// 2. 编排 — 排序、挂异常分支
///
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

    let llm_ref = resolve_llm(llm);

    let raw_scenes = step1_extract_scenes(&material, &topic, llm_ref);
    let json = step2_orchestrate(&raw_scenes, &material, &topic, llm_ref);

    let validation = crate::types::validate_lesson_json(&json);
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

fn step1_extract_scenes(material: &str, topic: &str, llm: &LLM) -> serde_json::Value {
    let prompt = format!(
        "你是一位课程设计专家。请从以下原始资料中提取「{}」涉及的所有操作步骤。\n\n\
         要求：\n\
         1. 每个步骤是一个独立的教学内容点\n\
         2. 只做提取，不做排序，不关联异常\n\
         3. 输出至少 4 个步骤，不超过 10 个\n\n\
         请严格按照以下 JSON 数组格式输出，不要包含其他内容：\n\
         [\n\
             {{\n\
                 \"title\": \"操作名称\",\n\
                 \"description\": \"操作描述（含具体内容和案例）\"\n\
             }}\n\
         ]",
        topic
    );

    let full_prompt = format!("{}\n\n## 原始资料\n\n{}", prompt, material);
    let messages = vec![Message::new("user", &full_prompt)];
    let resp = llm.complete(&messages, Default::default()).unwrap_or_else(|e| {
        eprintln!("错误：第 1 遍 LLM 调用失败 - {}", e);
        std::process::exit(1);
    });
    quanttide_agent::parse_structured_output(&resp.content).unwrap_or_else(|e| {
        eprintln!("错误：无法从第 1 遍结果解析 JSON - {}", e);
        eprintln!("原始回复：\n{}", resp.content);
        std::process::exit(1);
    })
}

fn step2_orchestrate(raw_scenes: &serde_json::Value, material: &str, topic: &str, llm: &LLM) -> serde_json::Value {
    let raw_json = serde_json::to_string_pretty(raw_scenes).unwrap();
    let prompt = format!(
        "你是一位课程设计专家。以下是「{}」课时的原始操作步骤列表（无序、无异常关联）：\n\n\
         {}\n\n\
         请完成编排：\n\
         1. 按实际操作流程排序\n\
         2. 为每个步骤判断是否需要异常分支，若需要则嵌套在 exception 字段中\n\
         3. 使用原始资料中的真实案例丰富描述\n\n\
         请严格按照以下 JSON 格式输出，不要包含其他内容：\n\
         {{\n\
             \"title\": \"课时标题\",\n\
             \"description\": \"教学目标\",\n\
             \"scenes\": [\n\
                 {{\n\
                     \"title\": \"步骤名称\",\n\
                     \"description\": \"具体操作描述（含真实案例）\",\n\
                     \"exception\": {{\n\
                         \"title\": \"异常名称\",\n\
                         \"description\": \"异常处理描述\"\n\
                     }}\n\
                 }}\n\
             ]\n\
         }}",
        topic, raw_json
    );

    let full_prompt = format!("{}\n\n## 原始资料（供参考案例）\n\n{}", prompt, material);
    let messages = vec![Message::new("user", &full_prompt)];
    let resp = llm.complete(&messages, Default::default()).unwrap_or_else(|e| {
        eprintln!("错误：第 2 遍 LLM 调用失败 - {}", e);
        std::process::exit(1);
    });
    quanttide_agent::parse_structured_output(&resp.content).unwrap_or_else(|e| {
        eprintln!("错误：无法从第 2 遍结果解析 JSON - {}", e);
        eprintln!("原始回复：\n{}", resp.content);
        std::process::exit(1);
    })
}

fn resolve_llm<'a>(llm: Option<&'a LLM>) -> &'a LLM {
    match llm {
        Some(l) => l,
        None => Box::leak(Box::new(LLM::default())),
    }
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
        "你是一位课程设计专家。请根据用户的设计指示，修改已有的课时蓝图。\n\n\
         设计要求：{}\n\n\
         注意事项：\n\
         1. 保持课时蓝图的操作流程结构，异常嵌套在父场景的 exception 字段中\n\
         2. 只修改用户要求的部分，其他部分保持不变\n\
         3. 输出完整的课时蓝图 JSON，不要省略任何字段\n\n\
         请严格按照以下 JSON 格式输出，不要包含其他内容：\n\
         {{\n\
             \"title\": \"课时标题\",\n\
             \"description\": \"教学目标\",\n\
             \"scenes\": [\n\
                 {{\n\
                     \"title\": \"步骤名称\",\n\
                     \"description\": \"操作描述\",\n\
                     \"exception\": {{\n\
                         \"title\": \"异常名称\",\n\
                         \"description\": \"异常处理描述\"\n\
                     }}\n\
                 }}\n\
             ]\n\
         }}",
        instruction
    );

    let full_prompt = format!("{}\n\n## 当前课时蓝图\n\n{}", prompt, existing);
    let default_llm;
    let llm_ref: &LLM = match llm {
        Some(l) => l,
        None => { default_llm = LLM::default(); &default_llm }
    };
    let messages = vec![Message::new("user", &full_prompt)];
    let resp = llm_ref.complete(&messages, Default::default()).unwrap_or_else(|e| {
        eprintln!("错误：{}", e);
        std::process::exit(1);
    });
    let json = quanttide_agent::parse_structured_output(&resp.content).unwrap_or_else(|e| {
        eprintln!("错误：无法从 LLM 回复中解析 JSON - {}", e);
        eprintln!("原始回复：\n{}", resp.content);
        std::process::exit(1);
    });
    let validation = crate::types::validate_lesson_json(&json);
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
