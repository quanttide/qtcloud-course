use quanttide_agent::{Message, Settings, LLM};
use std::process;

pub fn run(topic: &str) {
    let settings = Settings::from_env();
    let prompt = format!(
        "请为 {} 设计一份课程蓝图。\
         找到一个初学者在使用 {} 时最具体的操作困惑，回到设计源头解释它。\
         分课时描述教学框架，不是讲课稿。",
        topic, topic
    );

    let llm = LLM::new(
        &settings.llm_model,
        &settings.llm_base_url,
        &settings.llm_api_key,
    );
    let messages = vec![Message::new("user", &prompt)];
    let options = Default::default();

    match llm.complete(&messages, options) {
        Ok(resp) => println!("{}", resp.content),
        Err(e) => {
            eprintln!("错误：{}", e);
            process::exit(1);
        }
    }
}
