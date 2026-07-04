use std::fs;
use std::path::PathBuf;
use std::process;

use quanttide_agent::{LLM, Message, Settings};

pub fn run(topic: &str, input_path: Option<PathBuf>, output_path: Option<PathBuf>) {
    let settings = Settings::from_env();

    let mut prompt = format!(
        "请为 {} 设计一份课程蓝图。\
         找到一个初学者在使用 {} 时最具体的操作困惑，回到设计源头解释它。\
         分课时描述教学框架，不是讲课稿。",
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

    let llm = LLM::new(&settings.llm_model, &settings.llm_base_url, &settings.llm_api_key);
    let messages = vec![Message::new("user", &prompt)];
    let options = Default::default();

    let resp = llm.complete(&messages, options).unwrap_or_else(|e| {
        eprintln!("错误：{}", e);
        process::exit(1);
    });

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
